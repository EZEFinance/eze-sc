// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/EZEFinance.sol";
import "../src/MockUSDC.sol";
import "../src/MockUNI.sol";
import "../src/MockUSDT.sol";
import "../src/MockWETH.sol";
import "../src/MockDAI.sol";
import "../src/MockStakingAave.sol"; // USDC
import "../src/MockStakingCardano.sol"; // WETH
import "../src/MockStakingCompound.sol"; // USDT
import "../src/MockStakingRenzo.sol"; // DAI
import "../src/MockStakingUniswap.sol"; // UNI

contract DeployEZEFinance is Script {
    function run() external {
        // Deployment addresses for Uniswap V3 SwapRouter on Base networks
        address routerAddress;

        if (block.chainid == 8453) {
            // Base Mainnet
            routerAddress = 0x2626664c2603336E57B271c5C0b26F421741e481;
        } else if (block.chainid == 84532) {
            // Base Sepolia
            routerAddress = 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4;
        } else {
            revert(
                "Unsupported network - Please use Base Mainnet or Base Sepolia"
            );
        }

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockUSDC
        MockUSDC mockUSDC = new MockUSDC();
        console2.log("MockUSDC deployed to:", address(mockUSDC));

        // Deploy MockUNI
        MockUNI mockUNI = new MockUNI();
        console2.log("MockUNI deployed to:", address(mockUNI));

        // Deploy MockUSDT
        MockUSDT mockUSDT = new MockUSDT();
        console2.log("MockUSDT deployed to:", address(mockUSDT));

        // Deploy MockWETH
        MockWETH mockWETH = new MockWETH();
        console2.log("MockWETH deployed to:", address(mockWETH));

        // Deploy MockDAI
        MockDAI mockDAI = new MockDAI();
        console2.log("MockDAI deployed to:", address(mockDAI));

        // Deploy EZEFinance
        EZEFinance ezeFinance = new EZEFinance(routerAddress);
        console2.log("EZEFinance deployed to:", address(ezeFinance));

        // Deploy MockStakingUniswap with MockUNI as staking token
        uint8 fixedAPY = 10; // 10% APY
        uint256 durationInDays = 3; // 3 day staking period
        uint256 maxAmountStaked = 100_000 * 10 ** 6; // 100,000 MockUNI max stake

        MockStakingUniswap mockStakingUniswap = new MockStakingUniswap(
            address(mockUNI),
            fixedAPY,
            durationInDays,
            maxAmountStaked
        );
        console2.log(
            "MockStakingUniswap deployed to:",
            address(mockStakingUniswap)
        );

        // Deploy MockStakingCompound with MockUSDT as staking token
        fixedAPY = 15; // 15% APY
        durationInDays = 7; // 7 day staking period
        maxAmountStaked = 100_000 * 10 ** 6; // 50,000 MockUSDT max stake

        MockStakingCompound mockStakingCompound = new MockStakingCompound(
            address(mockUSDT),
            fixedAPY,
            durationInDays,
            maxAmountStaked
        );
        console2.log(
            "MockStakingCompound deployed to:",
            address(mockStakingCompound)
        );

        // Deploy MockStakingRenzo with MockDAI as staking token
        fixedAPY = 20; // 20% APY
        durationInDays = 14; // 14 day staking period
        maxAmountStaked = 100_000 * 10 ** 6; // 25,000 MockDAI max stake

        MockStakingRenzo mockStakingRenzo = new MockStakingRenzo(
            address(mockDAI),
            fixedAPY,
            durationInDays,
            maxAmountStaked
        );
        console2.log(
            "MockStakingRenzo deployed to:",
            address(mockStakingRenzo)
        );

        // Deploy MockStakingCardano with MockWETH as staking token
        fixedAPY = 25; // 25% APY
        durationInDays = 30; // 30 day staking period
        maxAmountStaked = 100_000 * 10 ** 6; // 100,000 MockWETH max stake

        MockStakingCardano mockStakingCardano = new MockStakingCardano(
            address(mockWETH),
            fixedAPY,
            durationInDays,
            maxAmountStaked
        );
        console2.log(
            "MockStakingCardano deployed to:",
            address(mockStakingCardano)
        );

        // Deploy MockStakingAave with MockUSDC as staking token
        fixedAPY = 30; // 30% APY
        durationInDays = 60; // 60 day staking period
        maxAmountStaked = 100_000 * 10 ** 6; // 100,000 MockUSDC max stake

        MockStakingAave mockStakingAave = new MockStakingAave(
            address(mockUSDC),
            fixedAPY,
            durationInDays,
            maxAmountStaked
        );
        console2.log("MockStakingAave deployed to:", address(mockStakingAave));

        vm.stopBroadcast();
    }
}
