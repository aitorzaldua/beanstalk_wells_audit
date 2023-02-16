// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TestHelper, console} from "test/TestHelper.sol";
import {LibContractInfo} from "src/libraries/LibContractInfo.sol";

contract LibMathTest is TestHelper {
    using LibContractInfo for address;

    function setUp() public {
        setupWell(2); // setting up a well just to get some mock tokens
    }

    function test_getSymbol() public {
        assertEq(address(tokens[0]).getSymbol(), "TOKEN1");
    }

    function test_getName() public {
        assertEq(address(tokens[0]).getName(), "Token 1");
    }

    function test_getDecimals() public {
        assertEq(address(tokens[0]).getDecimals(), 18);
    }
}
