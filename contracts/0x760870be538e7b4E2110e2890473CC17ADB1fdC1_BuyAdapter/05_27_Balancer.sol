// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";
import "../weth/IWETH.sol";
import "./IBalancerPool.sol";
import "../WethProvider.sol";

interface IBalancerProxy {
    struct Swap {
        address pool;
        uint256 tokenInParam; // tokenInAmount / maxAmountIn / limitAmountIn
        uint256 tokenOutParam; // minAmountOut / tokenAmountOut / limitAmountOut
        uint256 maxPrice;
    }

    function batchSwapExactIn(
        Swap[] calldata swaps,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut
    ) external returns (uint256 totalAmountOut);

    function batchSwapExactOut(
        Swap[] calldata swaps,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn
    ) external returns (uint256 totalAmountIn);

    function batchEthInSwapExactIn(
        Swap[] calldata swaps,
        address tokenOut,
        uint256 minTotalAmountOut
    ) external payable returns (uint256 totalAmountOut);

    function batchEthOutSwapExactIn(
        Swap[] calldata swaps,
        address tokenIn,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut
    ) external returns (uint256 totalAmountOut);

    function batchEthInSwapExactOut(Swap[] calldata swaps, address tokenOut)
        external
        payable
        returns (uint256 totalAmountIn);

    function batchEthOutSwapExactOut(
        Swap[] calldata swaps,
        address tokenIn,
        uint256 maxTotalAmountIn
    ) external returns (uint256 totalAmountIn);
}

abstract contract Balancer is WethProvider {
    using SafeMath for uint256;

    struct BalancerData {
        IBalancerProxy.Swap[] swaps;
    }

    function swapOnBalancer(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address,
        bytes calldata payload
    ) internal {
        BalancerData memory data = abi.decode(payload, (BalancerData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        uint256 totalInParam;
        for (uint256 i = 0; i < data.swaps.length; ++i) {
            totalInParam = totalInParam.add(data.swaps[i].tokenInParam);
        }

        for (uint256 i = 0; i < data.swaps.length; ++i) {
            IBalancerProxy.Swap memory _swap = data.swaps[i];
            uint256 adjustedInParam = _swap.tokenInParam.mul(fromAmount).div(totalInParam);
            Utils.approve(_swap.pool, _fromToken, adjustedInParam);
            IBalancerPool(_swap.pool).swapExactAmountIn(
                _fromToken,
                adjustedInParam,
                _toToken,
                _swap.tokenOutParam,
                _swap.maxPrice
            );
        }

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnBalancer(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchangeProxy,
        bytes calldata payload
    ) internal {
        BalancerData memory data = abi.decode(payload, (BalancerData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        _buyOnBalancer(_fromToken, _toToken, fromAmount, toAmount, data);

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function _buyOnBalancer(
        address _fromToken,
        address _toToken,
        uint256 fromAmount,
        uint256 toAmount,
        BalancerData memory data
    ) private {
        uint256 totalInParam;
        uint256 totalOutParam;
        for (uint256 i = 0; i < data.swaps.length; ++i) {
            IBalancerProxy.Swap memory _swap = data.swaps[i];
            totalInParam = totalInParam.add(_swap.tokenInParam);
            totalOutParam = totalOutParam.add(_swap.tokenOutParam);
        }

        for (uint256 i = 0; i < data.swaps.length; ++i) {
            IBalancerProxy.Swap memory _swap = data.swaps[i];
            uint256 adjustedInParam = _swap.tokenInParam.mul(fromAmount).div(totalInParam);
            uint256 adjustedOutParam = _swap.tokenOutParam.mul(toAmount).add(totalOutParam - 1).div(totalOutParam);
            Utils.approve(_swap.pool, _fromToken, adjustedInParam);
            IBalancerPool(_swap.pool).swapExactAmountOut(
                _fromToken,
                adjustedInParam,
                _toToken,
                adjustedOutParam,
                _swap.maxPrice
            );
        }
    }
}