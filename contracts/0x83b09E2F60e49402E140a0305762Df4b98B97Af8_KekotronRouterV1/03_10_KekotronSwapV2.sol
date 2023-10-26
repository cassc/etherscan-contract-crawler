// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IWETH.sol";
import "./interfaces/IPoolV2.sol";
import "./KekotronLib.sol";
import "./KekotronErrors.sol";

contract KekotronSwapV2 {
    address private immutable WETH;

    constructor(address weth) {
        WETH = weth;
    }

    struct SwapV2 {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        if (amountIn == 0) { 
            revert("KekotronErrors.InsufficientInputAmount"); 
        }
        if (reserveIn == 0 || reserveOut == 0) { 
            revert("KekotronErrors.InsufficientLiquidity"); 
        }

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;

        return numerator / denominator;
    }

    function _swapV2(SwapV2 memory param, address to) private returns(uint256) {
        bool zeroForOne = param.tokenIn < param.tokenOut;

        uint256 amountOut;
        {
            (uint256 reserve0, uint256 reserve1, ) = IPoolV2(param.pool).getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
            amountOut = _getAmountOut(IERC20(param.tokenIn).balanceOf(param.pool) - reserveInput, reserveInput, reserveOutput);
        }

        (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));

        uint256 balanceBefore = IERC20(param.tokenOut).balanceOf(to);
        IPoolV2(param.pool).swap(amount0Out, amount1Out, to, new bytes(0));
        uint256 balanceAfter = IERC20(param.tokenOut).balanceOf(to);

        return balanceAfter - balanceBefore;
    }

    function _swapExactEthForTokensV2(
        SwapV2 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {      
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee = param.amountIn * fee / 10_000;
            KekotronLib.safeTransferETH(feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        }

        KekotronLib.depositWETH(WETH, param.amountIn);
        KekotronLib.safeTransfer(WETH, param.pool, param.amountIn);

        uint256 amountOut = _swapV2(param, feeOut ? address(this) : msg.sender);

        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransfer(param.tokenOut, feeReceiver, amountFee);
        }

        if (feeOut) {
            KekotronLib.safeTransfer(param.tokenOut, msg.sender, amountOut);
        }
    }

    function _swapExactTokensForEthV2(
        SwapV2 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee = param.amountIn * fee / 10_000;
            KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        } 

        KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, param.pool, param.amountIn);

        uint256 amountOut = _swapV2(param, address(this));

        KekotronLib.withdrawWETH(WETH, amountOut);

        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransferETH(feeReceiver, amountFee);
        }

        KekotronLib.safeTransferETH(msg.sender, amountOut);
    }
    
    function _swapExactTokensForTokensV2(
        SwapV2 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee = param.amountIn * fee / 10_000;
            KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        } 

        KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, param.pool, param.amountIn);

        uint256 amountOut = _swapV2(param, feeOut ? address(this) : msg.sender);

        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransfer(param.tokenOut, feeReceiver, amountFee);
        }

        if (feeOut) {
            KekotronLib.safeTransfer(param.tokenOut, msg.sender, amountOut);
        }
    }

    function _swapExactInputV2(
        SwapV2 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) internal {
        if (param.tokenIn == address(0)) {
            param.tokenIn = WETH;
            return _swapExactEthForTokensV2(param, feeReceiver, fee, feeOn);
        }

        if (param.tokenOut == address(0)) {
            param.tokenOut = WETH;
            return _swapExactTokensForEthV2(param, feeReceiver, fee, feeOn);
        }

        return _swapExactTokensForTokensV2(param, feeReceiver, fee, feeOn);
    }

    function _callbackV2(
        address,
        uint256,
        uint256,
        bytes memory
    ) internal {}
}