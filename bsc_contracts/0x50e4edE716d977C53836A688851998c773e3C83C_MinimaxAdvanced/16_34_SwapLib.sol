// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IToken.sol";
import "../market/IMarket.sol";
import "../market/v2/IPairToken.sol";
import "../helpers/RevertLib.sol";

library SwapLib {
    using SafeERC20Upgradeable for IToken;

    struct SwapParams {
        IToken tokenIn;
        uint amountIn;
        IToken tokenOut;
        uint amountOutMin;
        uint swapKind;
        bytes swapArgs;
    }

    uint public constant SwapNoSwapKind = 1;

    uint public constant SwapMarketKind = 2;

    struct SwapMarket {
        bytes hints;
    }

    uint public constant SwapOneInchKind = 3;

    struct SwapOneInch {
        bytes oneInchCallData;
    }

    uint public constant SwapOneInchPairKind = 4;

    struct SwapOneInchPair {
        bytes oneInchCallDataToken0;
        bytes oneInchCallDataToken1;
    }

    function _swapNull(SwapParams memory params) private returns (uint) {
        require(address(params.tokenIn) == address(params.tokenOut) || address(params.tokenOut) == address(0));
        return params.amountIn;
    }

    function _swapMarket(
        SwapParams memory params,
        IMarket market,
        SwapMarket memory marketParams
    ) private returns (uint) {
        require(address(market) != address(0), "zero market");
        params.tokenIn.approve(address(market), params.amountIn);

        return
            market.swap(
                address(params.tokenIn),
                address(params.tokenOut),
                params.amountIn,
                params.amountOutMin,
                address(this),
                marketParams.hints
            );
    }

    function _swapOneInch(
        IToken tokenIn,
        uint amountIn,
        address oneInchRouter,
        bytes memory oneInchCallData
    ) private returns (uint) {
        require(oneInchRouter != address(0), "zero oneInchRouter");

        // If oneInchCallData is empty
        // that means that no swap should be done
        if (oneInchCallData.length == 0) {
            return amountIn;
        }

        // Approve twice more in case of amount fluctuation between estimate and transaction
        // TODO: set amountIn to MAX_INT on client, as long as it will be reduced to tokenIn balance anyway
        tokenIn.approve(oneInchRouter, amountIn * 2);

        (bool success, bytes memory retData) = oneInchRouter.call(oneInchCallData);
        RevertLib.propagateError(success, retData, "1inch");

        (uint amountOut, ) = abi.decode(retData, (uint, uint));
        return amountOut;
    }

    function _swapOneInchPair(
        SwapParams memory params,
        address oneInchRouter,
        SwapOneInchPair memory swapParams
    ) private returns (uint) {
        (IToken token0, uint amount0, IToken token1, uint amount1) = _burn(params.tokenIn);
        return
            _swapOneInch(token0, amount0, oneInchRouter, swapParams.oneInchCallDataToken0) +
            _swapOneInch(token1, amount1, oneInchRouter, swapParams.oneInchCallDataToken1);
    }

    function _burn(IToken token)
        private
        returns (
            IToken token0,
            uint amount0,
            IToken token1,
            uint amount1
        )
    {
        uint balance = token.balanceOf(address(this));
        token.transfer(address(token), balance);

        // TODO: when fee of contract is non-zero, then ensure fees from LP-tokens are not burned here
        (amount0, amount1) = IPairToken(address(token)).burn(address(this));
        token0 = IToken(IPairToken(address(token)).token0());
        token1 = IToken(IPairToken(address(token)).token1());
        return (token0, amount0, token1, amount1);
    }

    function swap(
        SwapParams memory params,
        IMarket market,
        address oneInchRouter
    ) external returns (uint amountIn, uint amountOut) {
        uint tokenInBalance = params.tokenIn.balanceOf(address(this));
        // this allows to pass amountIn = MAX_INT
        // in that case swap all available balance
        if (params.amountIn > tokenInBalance) {
            params.amountIn = tokenInBalance;
        }

        amountIn = params.amountIn;

        if (params.swapKind == SwapNoSwapKind) {
            amountOut = _swapNull(params);
        } else if (params.swapKind == SwapMarketKind) {
            SwapMarket memory decoded = abi.decode(params.swapArgs, (SwapMarket));
            amountOut = _swapMarket(params, market, decoded);
        } else if (params.swapKind == SwapOneInchKind) {
            SwapOneInch memory decoded = abi.decode(params.swapArgs, (SwapOneInch));
            amountOut = _swapOneInch(params.tokenIn, params.amountIn, oneInchRouter, decoded.oneInchCallData);
        } else if (params.swapKind == SwapOneInchPairKind) {
            SwapOneInchPair memory decoded = abi.decode(params.swapArgs, (SwapOneInchPair));
            amountOut = _swapOneInchPair(params, oneInchRouter, decoded);
        } else {
            revert("invalid swapKind param");
        }

        require(amountOut >= params.amountOutMin, "swap: amountOutMin");
    }
}