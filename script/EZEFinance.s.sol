// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/EZEFinance.sol";
import "../src/MockUSDC.sol";
import "../src/MockUNI.sol";

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
        
        MockUSDC mockUSDC = new MockUSDC();
        console2.log("MockUSDC deployed to:", address(mockUSDC));
        
        MockUNI mockUNI = new MockUNI();
        console2.log("MockUNI deployed to:", address(mockUNI));
        
        EZEFinance ezeFinance = new EZEFinance(routerAddress);
        console2.log("EZEFinance deployed to:", address(ezeFinance));
        
        vm.stopBroadcast();
    }
}