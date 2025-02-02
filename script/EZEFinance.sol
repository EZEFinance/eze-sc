// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/EZEFinance.sol";

contract EZEFinanceScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address routerAddress = vm.envAddress("UNIVERSAL_ROUTER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        EZEFinance ezeFinance = new EZEFinance(routerAddress);

        vm.stopBroadcast();
    }
}