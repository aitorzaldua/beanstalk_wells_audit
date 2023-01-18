/**
 * SPDX-License-Identifier: MIT
 **/
pragma solidity ^0.8.17;

import "test/TestHelper.sol";


contract RemoveLiquidityImbalancedTest is TestHelper {
    uint[] tokenAmountsOut;
    ConstantProduct2 cp;

    event RemoveLiquidity(uint lpAmountIn, uint[] tokenAmountsOut);

    function setUp() public {
        setupWell(2);
        addLiquidityEqualAmount(user, 1000 * 1e18);
        tokenAmountsOut.push(500 * 1e18);
        tokenAmountsOut.push(506 * 1e17);
    }

    function testGetRemoveLiquidityImbalancedOut() public {

        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(tokenAmountsOut);
        assertEq(lpAmountIn, 580 * 1e27);
    }

    function testRemoveLiquidityImbalanced() prank(user) public {
        uint maxLPAmountIn = 580 * 1e27;

        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(maxLPAmountIn, tokenAmountsOut);

        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);

        assertEq(well.balanceOf(user), (2000 - 580) * 1e27);

        assertEq(tokens[0].balanceOf(user), tokenAmountsOut[0], "incorrect token0 user amt");
        assertEq(tokens[1].balanceOf(user), tokenAmountsOut[1], "incorrect token1 user amt");

        assertEq(tokens[0].balanceOf(address(well)), 1500 * 1e18, "incorrect token0 well amt");
        assertEq(tokens[1].balanceOf(address(well)), 19494 * 1e17, "incorrect token0 well amt");
    }

    function testRemoveLiquidityImbalancedAmountOutTooHigh() prank(user) public {
        uint maxLPAmountIn = 579 * 1e27;

        vm.expectRevert("Well: slippage");
        well.removeLiquidityImbalanced(maxLPAmountIn, tokenAmountsOut, user);

    }

    function testRemoveLiqudityImbalancedFuzz(uint x, uint y) prank(user) public {
        uint[] memory amounts = new uint[](2);
        // limit remoove liquidity to account for slippage
        amounts[0] = bound(x,0,750e18); 
        amounts[1] = bound(y,0,750e18);

        uint userLPBalance = well.balanceOf(user);
        cp = new ConstantProduct2();
        bytes memory data = "";
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply =  cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
        uint amountOut = totalSupply - newLpTokenSupply;
        vm.expectEmit(true, true, true, true);
        emit RemoveLiquidity(amountOut,amounts);

        well.removeLiquidityImbalanced(userLPBalance,amounts,user);

        assertEq(well.balanceOf(user), userLPBalance - lpAmountIn, "Incorrect lp output");

        assertEq(tokens[0].balanceOf(user), amounts[0], "Incorrect token0 user balance");
        assertEq(tokens[1].balanceOf(user), amounts[1], "Incorrect token1 user balance");
        assertEq(tokens[0].balanceOf(address(well)), 2000e18 - amounts[0], "Incorrect token0 well balance");
        assertEq(tokens[1].balanceOf(address(well)), 2000e18 - amounts[1], "Incorrect token1 well balance");
    }
    
    // TODO: fuzz test: imbalanced ratio of tokens
    function testRemoveLiqudityFuzzUnbalanced(uint tknRemoved, uint imbalanceBias) public {
        uint[] memory amounts = new uint[](2);
        cp = new ConstantProduct2();
        bytes memory data = "";
        
        // limit remove liquidity to account for slippage
        amounts[0] = bound(tknRemoved, 1, 950e18);
        amounts[1] = amounts[0];
        imbalanceBias = bound(imbalanceBias,0,10e18);
       
        vm.prank(user2);
        well.swapFrom(tokens[0], tokens[1], imbalanceBias, 0, user2);
        vm.stopPrank();

        vm.startPrank(user);
        
        uint[] memory preWellBalance = new uint[](2);
        preWellBalance[0] = tokens[0].balanceOf(address(well));
        preWellBalance[1] = tokens[1].balanceOf(address(well));

        uint[] memory preUserBalance = new uint[](2);
        preUserBalance[0] = tokens[0].balanceOf(address(user));
        preUserBalance[1] = tokens[1].balanceOf(address(user));

        uint userLPBalance = well.balanceOf(user);
        uint[] memory balances = new uint[](2);
        uint lpAmountIn = well.getRemoveLiquidityImbalancedIn(amounts);
        balances[0] = tokens[0].balanceOf(address(well)) - amounts[0];
        balances[1] = tokens[1].balanceOf(address(well)) - amounts[1];

        uint newLpTokenSupply = cp.getLpTokenSupply(balances,data);
        uint totalSupply = well.totalSupply();
        uint amountOut = totalSupply - newLpTokenSupply;
        // vm.expectEmit(true, true, true, true);
        // emit RemoveLiquidity(amountOut,amounts);
        uint[] memory minAmt = new uint[](2);
        well.removeLiquidityImbalanced(userLPBalance,amounts,user);

        assertEq(well.balanceOf(user), userLPBalance - lpAmountIn, "Incorrect lp output");

        assertApproxEqAbs(tokens[0].balanceOf(user), preUserBalance[0] + amounts[0], 1e8, "Incorrect token0 user balance");
        assertApproxEqAbs(tokens[1].balanceOf(user),  preUserBalance[1] + amounts[1], 1e8, "Incorrect token1 user balance");
        assertApproxEqAbs(tokens[0].balanceOf(address(well)), preWellBalance[0] - amounts[0], 1e8, "Incorrect token0 well balance");
        assertApproxEqAbs(tokens[1].balanceOf(address(well)), preWellBalance[1] - amounts[1], 1e8, "Incorrect token1 well balance");

    }
}
