// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../src/EZEFinance.sol";
import "../src/MockUSDC.sol";
import "../src/MockUNI.sol";
import "../src/MockStakingUNI.sol";

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
            revert("Unsupported network - Please use Base Mainnet or Base Sepolia");
        }
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy MockUSDC
        MockUSDC mockUSDC = new MockUSDC();
        console2.log("MockUSDC deployed to:", address(mockUSDC));
        
        // Deploy MockUNI
        MockUNI mockUNI = new MockUNI();
        console2.log("MockUNI deployed to:", address(mockUNI));
        
        // Deploy EZEFinance
        EZEFinance ezeFinance = new EZEFinance(routerAddress);
        console2.log("EZEFinance deployed to:", address(ezeFinance));

        // Deploy MockStakingUNI with MockUNI as staking token
        uint8 fixedAPY = 10; // 10% APY
        uint256 durationInDays = 365; // 1 Year staking period
        uint256 maxAmountStaked = 100_000 * 10**18; // 100,000 MockUNI max stake

        MockStakingUNI mockStakingUNI = new MockStakingUNI(
            address(mockUNI), 
            fixedAPY, 
            durationInDays, 
            maxAmountStaked
        );
        console2.log("MockStakingUNI deployed to:", address(mockStakingUNI));

        vm.stopBroadcast();
    }
}
