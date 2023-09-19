// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract UniswapV2Router is BaseCore {

    using SafeMath for uint256;

    constructor() {

    }

    function _beforeSwap(ExactInputV2SwapParams calldata exactInput, bool supportingFeeOn) internal returns (bool isToETH, uint256 actualAmountIn, address[] memory paths, uint256 thisAddressBeforeBalance, uint256 toBeforeBalance) {
        require(exactInput.path.length == exactInput.pool.length + 1, "Invalid path");
        require(_wrapped_allowed[exactInput.wrappedToken], "Invalid wrapped address");
        actualAmountIn = calculateTradeFee(true, exactInput.amount, exactInput.fee, exactInput.signature);
        //检查第一个或最后一个是否为ETH
        address[] memory path = exactInput.path;
        address dstToken = path[exactInput.path.length - 1];
        if (TransferHelper.isETH(exactInput.path[0])) {
            require(msg.value == exactInput.amount, "Invalid msg.value");
            path[0] = exactInput.wrappedToken;
            TransferHelper.safeDeposit(exactInput.wrappedToken, actualAmountIn);
        } else {
            if (supportingFeeOn) {
                actualAmountIn = IERC20(path[0]).balanceOf(address(this));
                TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), exactInput.amount);
                actualAmountIn = IERC20(path[0]).balanceOf(address(this)).sub(actualAmountIn).sub(exactInput.fee);
            } else {
                TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), exactInput.amount);
            }
        }
        if (TransferHelper.isETH(dstToken)) {
            path[path.length - 1] = exactInput.wrappedToken;
            isToETH = true;
            thisAddressBeforeBalance = IERC20(exactInput.wrappedToken).balanceOf(address(this));
        } else {
            if (supportingFeeOn) {
                toBeforeBalance = IERC20(dstToken).balanceOf(exactInput.dstReceiver);
            }
        }
        paths = path;
    }

    function exactInputV2SwapAndGasUsed(ExactInputV2SwapParams calldata exactInput, uint256 deadline) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeV2Swap(exactInput, deadline);
        gasUsed = gasLeftBefore - gasleft();
    }

    function exactInputV2Swap(ExactInputV2SwapParams calldata exactInput, uint256 deadline) external payable returns (uint256 returnAmount) {
        returnAmount = _executeV2Swap(exactInput, deadline);
    }

    function _executeV2Swap(ExactInputV2SwapParams calldata exactInput, uint256 deadline) internal nonReentrant whenNotPaused returns (uint256 returnAmount) {
        require(deadline >= block.timestamp, "Expired");
        
        bool supportingFeeOn = exactInput.router >> 248 & 0xf == 1;
        {
            (bool isToETH, uint256 actualAmountIn, address[] memory paths, uint256 thisAddressBeforeBalance, uint256 toBeforeBalance) = _beforeSwap(exactInput, supportingFeeOn);
            
            TransferHelper.safeTransfer(paths[0], exactInput.pool[0], actualAmountIn);

            if (supportingFeeOn) {
                if(isToETH) {
                    _swapSupportingFeeOnTransferTokens(address(uint160(exactInput.router)), paths, exactInput.pool, address(this));
                    returnAmount = IERC20(exactInput.wrappedToken).balanceOf(address(this)).sub(thisAddressBeforeBalance);
                } else {
                    _swapSupportingFeeOnTransferTokens(address(uint160(exactInput.router)), paths, exactInput.pool, exactInput.dstReceiver);
                    returnAmount = IERC20(paths[paths.length - 1]).balanceOf(exactInput.dstReceiver).sub(toBeforeBalance);
                }
            } else {
                uint[] memory amounts = IUniswapV2(address(uint160(exactInput.router))).getAmountsOut(actualAmountIn, paths);
                if(isToETH) {
                    _swap(amounts, paths, exactInput.pool, address(this));
                    returnAmount = IERC20(exactInput.wrappedToken).balanceOf(address(this)).sub(thisAddressBeforeBalance);
                } else {
                    _swap(amounts, paths, exactInput.pool, exactInput.dstReceiver);
                    returnAmount = amounts[amounts.length - 1];
                }
            }

            require(returnAmount >= exactInput.minReturnAmount, "Too little received");
            if (isToETH) {
                TransferHelper.safeWithdraw(exactInput.wrappedToken, returnAmount);
                TransferHelper.safeTransferETH(exactInput.dstReceiver, returnAmount);
            }
        }
        string memory channel = exactInput.channel;

        _emitTransit(exactInput.path[0], exactInput.path[exactInput.path.length - 1], exactInput.dstReceiver, exactInput.amount, returnAmount, 0, channel);
        
    }

    function _swap(uint[] memory amounts, address[] memory path, address[] memory pool, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = input < output ? (input, output) : (output, input);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pool[i + 1] : _to;
            IUniswapV2(pool[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function _swapSupportingFeeOnTransferTokens(address router, address[] memory path, address[] memory pool, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = input < output ? (input, output) : (output, input);
            IUniswapV2 pair = IUniswapV2(pool[i]);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = IUniswapV2(router).getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? pool[i + 1] : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

}