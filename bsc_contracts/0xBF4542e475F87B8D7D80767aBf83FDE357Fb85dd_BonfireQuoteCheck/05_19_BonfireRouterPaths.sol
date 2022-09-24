// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../swap/IBonfireFactory.sol";
import "../swap/IBonfirePair.sol";
import "../swap/BonfireSwapHelper.sol";
import "../token/IBonfireTokenWrapper.sol";
import "../token/IBonfireTokenTracker.sol";
import "../token/IBonfireProxyToken.sol";
import "../utils/BonfireTokenHelper.sol";

library BonfireRouterPaths {
    address public constant wrapper =
        address(0xBFbb27219f18d7463dD91BB4721D445244F5d22D);
    address public constant tracker =
        address(0xBFac04803249F4C14f5d96427DA22a814063A5E1);

    error BadUse(uint256 location);
    error BadValues(uint256 v1, uint256 v2);
    error BadAccounts(uint256 location, address a1, address a2);

    function getBestPath(
        address token0,
        address token1,
        uint256 amountIn,
        address to,
        address[] calldata uniswapFactories,
        address[] calldata intermediateTokens
    )
        external
        view
        returns (
            uint256 value,
            address[] memory poolPath,
            address[] memory tokenPath
        )
    {
        tokenPath = new address[](2);
        tokenPath[0] = token0;
        tokenPath[1] = token1;
        if (
            _proxySourceMatch(token0, token1) ||
            _proxySourceMatch(token1, token0) ||
            (BonfireSwapHelper.isProxy(token0) &&
                BonfireSwapHelper.isProxy(token1) &&
                IBonfireProxyToken(token0).sourceToken() ==
                IBonfireProxyToken(token1).sourceToken() &&
                IBonfireProxyToken(token0).chainid() ==
                IBonfireProxyToken(token1).chainid())
        ) {
            /*
             * Cases where we simply want to wrap/unwrap/convert
             * chainid is correct
             * 1. both proxy of same sourceToken
             * 2/3. one proxy of the other
             */
            address wrapper0 = BonfireTokenHelper.getWrapper(token0);
            address wrapper1 = BonfireTokenHelper.getWrapper(token1);
            if (wrapper0 == address(0)) {
                //wrap
                value = _wrapperQuote(token0, token1, amountIn);
                poolPath = new address[](1);
                poolPath[0] = wrapper1;
            } else if (wrapper1 == address(0) || wrapper1 == wrapper0) {
                //unwrap or convert
                value = _wrapperQuote(token0, token1, amountIn);
                poolPath = new address[](1);
                poolPath[0] = wrapper0;
            } else {
                /*
                 * This special case is unwrapping in one TokenWrapper and
                 * wrapping in another.
                 */
                poolPath = new address[](2);
                poolPath[0] = wrapper0;
                poolPath[1] = wrapper1;
                tokenPath = new address[](3);
                tokenPath[0] = token0;
                tokenPath[1] = IBonfireProxyToken(token0).sourceToken();
                tokenPath[2] = token1;
                value = _wrapperQuote(tokenPath[0], tokenPath[1], amountIn);
                value = _wrapperQuote(tokenPath[1], tokenPath[2], value);
            }
            value = emulateTax(token1, value, IERC20(token1).balanceOf(to));
        }
        {
            //regular swap checks
            address[] memory t;
            address[] memory p;
            uint256 v;
            (p, t, v) = _getBestPath(
                token0,
                token1,
                amountIn,
                to,
                uniswapFactories,
                intermediateTokens
            );
            if (v > value) {
                tokenPath = t;
                poolPath = p;
                value = v;
            }
            //folowing three additional checks for proxy paths
            if (
                BonfireSwapHelper.isProxy(token0) &&
                BonfireSwapHelper.isProxy(token1) &&
                IBonfireProxyToken(token0).chainid() == block.chainid &&
                IBonfireProxyToken(token1).chainid() == block.chainid &&
                IBonfireProxyToken(token0).sourceToken() !=
                IBonfireProxyToken(token1).sourceToken()
            ) {
                //also try additional unwrapping of token0 and wrapping of token1
                (p, t, v) = _getBestUnwrapSwapWrapPath(
                    token0,
                    token1,
                    amountIn,
                    uniswapFactories,
                    intermediateTokens
                );
                if (v > value) {
                    poolPath = p;
                    tokenPath = t;
                    poolPath = new address[](p.length + 2);
                    tokenPath = new address[](t.length + 2);
                    for (uint256 x = 0; x < p.length; x++) {
                        poolPath[x + 1] = p[x];
                    }
                    for (uint256 x = 0; x < t.length; x++) {
                        tokenPath[x + 1] = t[x];
                    }
                    poolPath[0] = wrapper;
                    poolPath[poolPath.length - 1] = wrapper;
                    tokenPath[0] = token0;
                    tokenPath[tokenPath.length - 1] = token1;
                    value = v;
                }
            }
            if (
                BonfireSwapHelper.isProxy(token0) &&
                IBonfireProxyToken(token0).chainid() == block.chainid &&
                IBonfireProxyToken(token0).sourceToken() != token1
            ) {
                //also try additional unwrapping of token0
                (p, t, v) = _getBestUnwrapSwapPath(
                    token0,
                    token1,
                    amountIn,
                    to,
                    uniswapFactories,
                    intermediateTokens
                );
                if (v > value) {
                    poolPath = new address[](p.length + 1);
                    tokenPath = new address[](t.length + 1);
                    for (uint256 x = 0; x < p.length; x++) {
                        poolPath[x + 1] = p[x];
                    }
                    for (uint256 x = 0; x < t.length; x++) {
                        tokenPath[x + 1] = t[x];
                    }
                    poolPath[0] = wrapper;
                    tokenPath[0] = token0;
                    value = v;
                }
            }
            if (
                BonfireSwapHelper.isProxy(token1) &&
                IBonfireProxyToken(token1).chainid() == block.chainid &&
                IBonfireProxyToken(token1).sourceToken() != token0
            ) {
                //also try additional wrapping of token1
                (p, t, v) = _getBestSwapWrapPath(
                    token0,
                    token1,
                    amountIn,
                    uniswapFactories,
                    intermediateTokens
                );
                if (v > value) {
                    poolPath = new address[](p.length + 1);
                    tokenPath = new address[](t.length + 1);
                    for (uint256 x = 0; x < p.length; x++) {
                        poolPath[x] = p[x];
                    }
                    for (uint256 x = 0; x < t.length; x++) {
                        tokenPath[x] = t[x];
                    }
                    poolPath[poolPath.length - 1] = wrapper;
                    tokenPath[tokenPath.length - 1] = token1;
                    value = v;
                }
            }
        }
    }

    function _getBestUnwrapSwapWrapPath(
        address token0,
        address token1,
        uint256 amount,
        address[] calldata uniswapFactories,
        address[] calldata intermediateTokens
    )
        private
        view
        returns (
            address[] memory,
            address[] memory,
            uint256
        )
    {
        address[] memory poolPath;
        address[] memory tokenPath;
        amount = emulateTax(token0, amount, uint256(0));
        amount = IBonfireTokenWrapper(wrapper).sharesToToken(
            IBonfireProxyToken(token0).sourceToken(),
            IBonfireProxyToken(token0).tokenToShares(amount)
        );
        (poolPath, tokenPath, amount) = _getBestPath(
            IBonfireProxyToken(token0).sourceToken(),
            IBonfireProxyToken(token1).sourceToken(),
            amount,
            address(0),
            uniswapFactories,
            intermediateTokens
        );
        amount = IBonfireProxyToken(token1).sharesToToken(
            IBonfireTokenWrapper(wrapper).tokenToShares(
                IBonfireProxyToken(token1).sourceToken(),
                amount
            )
        );
        amount = emulateTax(token1, amount, uint256(0));
        return (poolPath, tokenPath, amount);
    }

    function _getBestUnwrapSwapPath(
        address token0,
        address token1,
        uint256 amount,
        address to,
        address[] calldata uniswapFactories,
        address[] calldata intermediateTokens
    )
        private
        view
        returns (
            address[] memory,
            address[] memory,
            uint256
        )
    {
        address[] memory poolPath;
        address[] memory tokenPath;
        amount = emulateTax(token0, amount, uint256(0));
        amount = IBonfireTokenWrapper(wrapper).sharesToToken(
            IBonfireProxyToken(token0).sourceToken(),
            IBonfireProxyToken(token0).tokenToShares(amount)
        );
        (poolPath, tokenPath, amount) = _getBestPath(
            IBonfireProxyToken(token0).sourceToken(),
            token1,
            amount,
            to,
            uniswapFactories,
            intermediateTokens
        );
        return (poolPath, tokenPath, amount);
    }

    function _getBestSwapWrapPath(
        address token0,
        address token1,
        uint256 amount,
        address[] calldata uniswapFactories,
        address[] calldata intermediateTokens
    )
        private
        view
        returns (
            address[] memory,
            address[] memory,
            uint256
        )
    {
        address[] memory poolPath;
        address[] memory tokenPath;
        (poolPath, tokenPath, amount) = _getBestPath(
            token0,
            IBonfireProxyToken(token1).sourceToken(),
            amount,
            address(0),
            uniswapFactories,
            intermediateTokens
        );
        amount = IBonfireProxyToken(token1).sharesToToken(
            IBonfireTokenWrapper(wrapper).tokenToShares(
                IBonfireProxyToken(token1).sourceToken(),
                amount
            )
        );
        amount = emulateTax(token1, amount, uint256(0));
        return (poolPath, tokenPath, amount);
    }

    /*
     * this function internally calls  quote
     */
    function _getBestPath(
        address token0,
        address token1,
        uint256 amountIn,
        address to,
        address[] calldata uniswapFactories,
        address[] calldata intermediateTokens
    )
        private
        view
        returns (
            address[] memory poolPath,
            address[] memory tokenPath,
            uint256 amountOut
        )
    {
        tokenPath = new address[](2);
        tokenPath[0] = token0;
        tokenPath[1] = token1;
        poolPath = new address[](1);
        (poolPath[0], amountOut) = getBestPool(
            token0,
            token1,
            amountIn,
            to,
            uniswapFactories
        );
        // use intermediate tokens
        tokenPath = new address[](3);
        tokenPath[0] = token0;
        tokenPath[2] = token1;
        address tokenI = address(0);
        for (uint256 i = 0; i < intermediateTokens.length; i++) {
            tokenPath[1] = intermediateTokens[i];
            if (tokenPath[1] == token0 || tokenPath[1] == token1) continue;
            (address[] memory p, uint256 v) = getBestTwoPoolPath(
                tokenPath,
                amountIn,
                to,
                uniswapFactories
            );
            if (v > amountOut) {
                poolPath = p;
                amountOut = v;
                tokenI = tokenPath[1];
            }
        }
        if (tokenI != address(0)) {
            tokenPath[1] = tokenI;
        } else {
            tokenPath = new address[](2);
            tokenPath[0] = token0;
            tokenPath[1] = token1;
        }
    }

    function getBestPool(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to,
        address[] calldata uniswapFactories
    ) public view returns (address pool, uint256 amountOut) {
        for (uint256 i = 0; i < uniswapFactories.length; i++) {
            address p = IBonfireFactory(uniswapFactories[i]).getPair(
                tokenIn,
                tokenOut
            );
            if (p == address(0)) continue;
            uint256 v = _swapQuote(p, tokenIn, tokenOut, amountIn);
            if (v > amountOut) {
                pool = p;
                amountOut = v;
            }
        }
        amountOut = emulateTax(
            tokenOut,
            amountOut,
            IERC20(tokenOut).balanceOf(to)
        );
    }

    function getBestTwoPoolPath(
        address[] memory tokenPath,
        uint256 amountIn,
        address to,
        address[] calldata uniswapFactories
    ) public view returns (address[] memory poolPath, uint256 amountOut) {
        poolPath = new address[](2);
        address[] memory p = new address[](2);
        uint256 value = amountIn;
        for (uint256 j = 0; j < uniswapFactories.length; j++) {
            p[0] = IBonfireFactory(uniswapFactories[j]).getPair(
                tokenPath[0],
                tokenPath[1]
            );
            if (p[0] == address(0)) continue;
            value = _swapQuote(p[0], tokenPath[0], tokenPath[1], amountIn);
            for (uint256 k = 0; k < uniswapFactories.length; k++) {
                p[1] = IBonfireFactory(uniswapFactories[k]).getPair(
                    tokenPath[1],
                    tokenPath[2]
                );
                if (p[1] == address(0)) continue;
                uint256 v = _swapQuote(p[1], tokenPath[1], tokenPath[2], value);
                if (v > amountOut) {
                    poolPath = new address[](p.length);
                    for (uint256 x = 0; x < p.length; x++) {
                        poolPath[x] = p[x];
                    }
                    amountOut = v;
                }
            }
        }
        amountOut = emulateTax(
            tokenPath[2],
            amountOut,
            IERC20(tokenPath[2]).balanceOf(to)
        );
    }

    function _proxySourceMatch(address tokenP, address tokenS)
        private
        view
        returns (bool)
    {
        return (BonfireSwapHelper.isProxy(tokenP) &&
            IBonfireProxyToken(tokenP).chainid() == block.chainid &&
            IBonfireProxyToken(tokenP).sourceToken() == tokenS);
    }

    function emulateTax(
        address token,
        uint256 incomingAmount,
        uint256 targetBalance
    ) public view returns (uint256 expectedAmount) {
        uint256 totalTaxP = IBonfireTokenTracker(tracker).getTotalTaxP(token);
        if (totalTaxP == 0) {
            expectedAmount = incomingAmount;
        } else {
            uint256 reflectionTaxP = IBonfireTokenTracker(tracker)
                .getReflectionTaxP(token);
            uint256 taxQ = IBonfireTokenTracker(tracker).getTaxQ(token);
            uint256 includedSupply = IBonfireTokenTracker(tracker)
                .includedSupply(token);
            uint256 tax = (incomingAmount * totalTaxP) / taxQ;
            uint256 reflection = (incomingAmount * reflectionTaxP) / taxQ;
            if (includedSupply > tax) {
                reflection =
                    (reflection * (targetBalance + incomingAmount - tax)) /
                    (includedSupply - tax);
            } else {
                reflection = 0;
            }
            expectedAmount = incomingAmount - tax + reflection;
        }
    }

    function _swapQuote(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private view returns (uint256 amountOut) {
        //no wrapper interaction!
        amountIn = emulateTax(
            tokenIn,
            amountIn,
            IERC20(tokenIn).balanceOf(pool)
        );
        uint256 projectedBalanceB;
        uint256 reserveB;
        (amountOut, reserveB, projectedBalanceB) = BonfireSwapHelper
            .getAmountOutFromPool(amountIn, tokenOut, pool);
        if (IBonfireTokenTracker(tracker).getReflectionTaxP(tokenOut) > 0) {
            amountOut = BonfireSwapHelper.reflectionAdjustment(
                tokenOut,
                pool,
                amountOut,
                projectedBalanceB
            );
        }
        if (amountOut > reserveB)
            //amountB exceeds current reserve, problem with Uniswap even if balanceB justifies that value, return max
            amountOut = reserveB - 1;
    }

    function _wrapperQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private view returns (uint256 amountOut) {
        //wrapper interaction
        address t0 = BonfireTokenHelper.getSourceToken(tokenIn);
        address t1 = BonfireTokenHelper.getSourceToken(tokenOut);
        address _wrapper = BonfireTokenHelper.getWrapper(tokenIn);
        if (_wrapper != address(0)) {
            address w2 = BonfireTokenHelper.getWrapper(tokenOut);
            if (w2 != address(0)) {
                if (_wrapper != w2) {
                    revert BadAccounts(0, _wrapper, w2); //Wrapper mismatch
                }
                //convert
                amountOut = IBonfireProxyToken(tokenOut).sharesToToken(
                    IBonfireProxyToken(tokenIn).tokenToShares(amountIn)
                );
            } else {
                //unwrap
                if (t0 != tokenOut) {
                    revert BadAccounts(1, t0, t1); //proxy/source mismatch
                }
                amountOut = IBonfireTokenWrapper(_wrapper).sharesToToken(
                    tokenOut,
                    IBonfireProxyToken(tokenIn).tokenToShares(amountIn)
                );
            }
        } else {
            _wrapper = BonfireTokenHelper.getWrapper(tokenOut);
            if (_wrapper == address(0)) {
                revert BadAccounts(2, t0, t1); //no wrapped token
            }
            //wrap
            if (t1 != tokenIn) {
                revert BadAccounts(3, t0, t1); //proxy/source mismatch
            }
            amountIn = emulateTax(tokenIn, amountIn, 0);
            amountOut = IBonfireProxyToken(tokenOut).sharesToToken(
                IBonfireTokenWrapper(_wrapper).tokenToShares(tokenIn, amountIn)
            );
        }
    }

    function wrapperQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) external view returns (uint256 amountOut) {
        amountOut = _wrapperQuote(tokenIn, tokenOut, amountIn);
        amountOut = emulateTax(
            tokenOut,
            amountOut,
            IERC20(tokenOut).balanceOf(to)
        );
    }

    function quote(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) external view returns (uint256 amountOut) {
        if (tokenPath.length != poolPath.length + 1) {
            revert BadValues(tokenPath.length, poolPath.length); //poolPath and tokenPath lengths do not match
        }
        for (uint256 i = 0; i < tokenPath.length; i++) {
            if (tokenPath[i] == address(0)) {
                revert BadUse(i); //malformed tokenPath
            }
        }
        for (uint256 i = 0; i < poolPath.length; i++) {
            if (poolPath[i] == address(0)) {
                revert BadUse(i); //malformed poolPath
            }
        }
        for (uint256 i = 0; i < poolPath.length; i++) {
            if (BonfireSwapHelper.isWrapper(poolPath[i])) {
                amount = _wrapperQuote(tokenPath[i], tokenPath[i + 1], amount);
            } else {
                amount = _swapQuote(
                    poolPath[i],
                    tokenPath[i],
                    tokenPath[i + 1],
                    amount
                );
            }
        }
        //remove tax but add reflection as applicable
        amountOut = emulateTax(
            tokenPath[tokenPath.length - 1],
            amount,
            IERC20(tokenPath[tokenPath.length - 1]).balanceOf(to)
        );
    }
}