// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "@uniswap/v4-periphery/src/base/hooks/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks, IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract MEVProtectionHook is BaseHook {
    using FixedPointMathLib for uint256;

    uint256 public constant BASE_MEV_COOLDOWN_TIME = 30;
    uint256 public constant BASE_MEV_COOLDOWN_BLOCKS = 2;
    uint24 public constant MIN_FEE = 5; // 0.05%
    uint24 public constant MAX_FEE = 100; // 1.0%
    uint24 public constant FEE_CAPTURE_RATE = 650; // 65% in basis points
    uint256 public constant FEE_SCALING_FACTOR = 1e12;

    struct FeeState {
        int24 currentTick;
        uint64 lastUpdated;
        uint128 volatilityEMA;
        uint128 swapSizeEMA;
        uint64 lastBlock;
    }

    mapping(bytes32 => FeeState) public feeStates;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function beforeSwap(
        address,
        IPoolManager.PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        bytes32 poolId = keccak256(abi.encode(key));
        FeeState storage fee = feeStates[poolId];

        // Adaptive cooldown with sigmoid decay
        uint256 cooldownTime = BASE_MEV_COOLDOWN_TIME +
            (fee.volatilityEMA * BASE_MEV_COOLDOWN_TIME) /
            (1e6 + fee.volatilityEMA);

        if (block.timestamp < fee.lastUpdated + cooldownTime) {
            revert("MEV cooldown active");
        }

        // Update metrics
        int24 currentTick = poolManager.getCurrentTick(key);
        int24 tickDiff = _abs(currentTick - fee.currentTick);
        uint128 newVol = uint128(
            (fee.volatilityEMA * 9 + uint128(tickDiff)) / 10
        );

        uint128 swapSize = uint128(
            params.amountSpecified > 0
                ? uint256(params.amountSpecified)
                : uint256(-params.amountSpecified)
        );
        uint128 newSwap = uint128((fee.swapSizeEMA * 9 + swapSize) / 10);

        // Calculate MEV-sensitive fee
        uint256 mevOpportunity = uint256(newVol) * swapSize;
        uint256 targetFee = MIN_FEE +
            (mevOpportunity * FEE_CAPTURE_RATE) /
            FEE_SCALING_FACTOR;

        uint24 newFee = uint24(targetFee > MAX_FEE ? MAX_FEE : targetFee);

        // Single SSTORE update
        feeStates[poolId] = FeeState({
            currentTick: currentTick,
            lastUpdated: uint64(block.timestamp),
            volatilityEMA: newVol,
            swapSizeEMA: newSwap,
            lastBlock: uint64(block.number)
        });

        poolManager.setFee(key, newFee);

        return this.beforeSwap.selector;
    }

    function _abs(int24 value) internal pure returns (int24) {
        return value >= 0 ? value : -value;
    }
}