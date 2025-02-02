pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {EZEFinance} from "../src/EZEFinance.sol";
import {UniversalRouter} from "@uniswap/universal-router/contracts/UniversalRouter.sol";

contract EZEFinanceTest is Test {
    EZEFinance public ezeFinance;
    UniversalRouter public router;

    function setUp() public {
        // Assuming UniversalRouter constructor only needs permit2 address
        address permit2 = address(0x1); // Mock permit2 address
        router = new UniversalRouter(permit2);
        ezeFinance = new EZEFinance(address(router));
    }
}