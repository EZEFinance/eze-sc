// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/EZEFinance.sol";
import "./MockUSDC.t.sol";
import "./MockUNI.t.sol";
import "./MockUniswapRouter.t.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error OwnableUnauthorizedAccount(address account);
error EnforcedPause();

contract EZEFinanceTest is Test {
    address public owner;

    function setUp() public {
        owner = address(this);
    }
}
