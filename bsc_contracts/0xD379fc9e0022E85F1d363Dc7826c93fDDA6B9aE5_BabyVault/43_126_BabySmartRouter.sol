// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/BabyLibrarySmartRouter.sol";
import "../interfaces/IBabySmartRouter.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/ISwapMining.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "./BabyBaseRouter.sol";

contract BabySmartRouter is BabyBaseRouter, IBabySmartRouter {
    using SafeMath for uint;

    address immutable public normalRouter;

    constructor(
        address _factory, 
        address _WETH, 
        address _swapMining, 
        address _routerFeeReceiver,
        address _normalRouter
    ) BabyBaseRouter(_factory, _WETH, _swapMining, _routerFeeReceiver) {
        normalRouter = _normalRouter;
    }

    function routerFee(address _factory, address _user, address _token, uint _amount) internal returns (uint) {
        if (routerFeeReceiver != address(0) && _factory == factory) {
            uint fee = _amount.mul(1).div(1000);
            if (fee > 0) {
                if (_user == address(this)) {
                    TransferHelper.safeTransfer(_token, routerFeeReceiver, fee);
                } else {
                    TransferHelper.safeTransferFrom(
                        _token, msg.sender, routerFeeReceiver, fee
                    );
                }
                _amount = _amount.sub(fee);
            }
        }
        return _amount;
    }

    fallback() external payable {
        babyRouterDelegateCall(msg.data);
    }

    function babyRouterDelegateCall(bytes memory data) internal {
        (bool success, ) = normalRouter.delegatecall(data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    function _swap(
        uint[] memory amounts, 
        address[] memory path, 
        address[] memory factories, 
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BabyLibrarySmartRouter.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            if (swapMining != address(0)) {
                ISwapMining(swapMining).swap(msg.sender, input, output, amountOut);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? address(this) : _to;
            IBabyPair(BabyLibrarySmartRouter.pairFor(factories[i], input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
            if (i < path.length - 2) {
                amounts[i + 1] = routerFee(factories[i + 1], address(this), path[i + 1], amounts[i + 1]);
                TransferHelper.safeTransfer(path[i + 1], BabyLibrarySmartRouter.pairFor(factories[i + 1], output, path[i + 2]), amounts[i + 1]);
            }
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address[] memory factories,
        uint[] memory fees,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BabyLibrarySmartRouter.getAggregationAmountsOut(factories, fees, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BabyRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        amounts[0] = routerFee(factories[0], msg.sender, path[0], amounts[0]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, factories, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address[] memory factories,
        uint[] memory fees,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BabyLibrarySmartRouter.getAggregationAmountsIn(factories, fees, amountOut, path);
        require(amounts[0] <= amountInMax, 'BabyRouter: EXCESSIVE_INPUT_AMOUNT');
        amounts[0] = routerFee(factories[0], msg.sender, path[0], amounts[0]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, factories, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] memory path, 
        address[] memory factories, 
        uint[] memory fees, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'BabyRouter: INVALID_PATH');
        amounts = BabyLibrarySmartRouter.getAggregationAmountsOut(factories, fees,  msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BabyRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        amounts[0] = routerFee(factories[0], address(this), path[0], amounts[0]);
        assert(IWETH(WETH).transfer(BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]));
        _swap(amounts, path, factories, to);
    }

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] memory path, 
        address[] memory factories, 
        uint[] memory fees, 
        address to, 
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'BabyRouter: INVALID_PATH');
        amounts = BabyLibrarySmartRouter.getAggregationAmountsIn(factories, fees, amountOut, path);
        require(amounts[0] <= amountInMax, 'BabyRouter: EXCESSIVE_INPUT_AMOUNT');
        amounts[0] = routerFee(factories[0], msg.sender, path[0], amounts[0]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, factories, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] memory path, 
        address[] memory factories, 
        uint[] memory fees, 
        address to, 
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'BabyRouter: INVALID_PATH');
        amounts = BabyLibrarySmartRouter.getAggregationAmountsOut(factories, fees, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BabyRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        amounts[0] = routerFee(factories[0], msg.sender, path[0], amounts[0]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, factories, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut, 
        address[] memory path, 
        address[] memory factories, 
        uint[] memory fees, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'BabyRouter: INVALID_PATH');
        amounts = BabyLibrarySmartRouter.getAggregationAmountsIn(factories, fees, amountOut, path);
        require(amounts[0] <= msg.value, 'BabyRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        uint oldAmount = amounts[0];
        amounts[0] = routerFee(factories[0], address(this), path[0], amounts[0]);
        assert(IWETH(WETH).transfer(BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amounts[0]));
        _swap(amounts, path, factories, to);
        // refund dust eth, if any
        if (msg.value > oldAmount) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(oldAmount));
    }

    function _swapSupportingFeeOnTransferTokens(
        address[] memory path, 
        address[] memory factories, 
        uint[] memory fees, 
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BabyLibrarySmartRouter.sortTokens(input, output);
            IBabyPair pair = IBabyPair(BabyLibrarySmartRouter.pairFor(factories[i], input, output));
            //uint amountInput;
            //uint amountOutput;
            uint[] memory amounts = new uint[](2);
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amounts[0] = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amounts[1] = BabyLibrarySmartRouter.getAmountOutWithFee(amounts[0], reserveInput, reserveOutput, fees[i]);
            }
            if (swapMining != address(0)) {
                ISwapMining(swapMining).swap(msg.sender, input, output, amounts[1]);
            }
            (amounts[0], amounts[1]) = input == token0 ? (uint(0), amounts[1]) : (amounts[1], uint(0));
            address to = i < path.length - 2 ? address(this) : _to;
            pair.swap(amounts[0], amounts[1], to, new bytes(0));
            if (i < path.length - 2) {
                routerFee(factories[i + 1], address(this), output, IERC20(output).balanceOf(address(this)));
                TransferHelper.safeTransfer(path[i + 1], BabyLibrarySmartRouter.pairFor(factories[i + 1], output, path[i + 2]), IERC20(output).balanceOf(address(this)));
            }
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address[] memory factories,
        uint[] memory fees,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        amountIn = routerFee(factories[0], msg.sender, path[0], amountIn);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, factories, fees,  to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BabyRouter:INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] memory path,
        address[] memory factories,
        uint[] memory fees,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) {
        require(path[0] == WETH, 'BabyRouter');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        amountIn = routerFee(factories[0], address(this), path[0], amountIn);
        assert(IWETH(WETH).transfer(BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, factories, fees, to);
        uint balanceAfter = IERC20(path[path.length - 1]).balanceOf(to);
        require(
            balanceAfter.sub(balanceBefore) >= amountOutMin,
            'BabyRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address[] memory factories,
        uint[] memory fees,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'BabyRouter: INVALID_PATH');
        amountIn = routerFee(factories[0], msg.sender, path[0], amountIn);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BabyLibrarySmartRouter.pairFor(factories[0], path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, factories, fees, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BabyRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}