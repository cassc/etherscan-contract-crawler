// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./Constants.BinaryBet.sol";
import "./OracleLibrary.sol";

/// @title Library for interacting with uniswap V3 pools
/// @notice Provides function to get a "tick" vs USDC for a given pool Note: do not confuse this with pool tick
library Market {
    /// @notice Queries current "tick" vs USDC on a pool.
    /// tick = log_1.0001(token_price), where token price numerator is **always** USDC and denominator is pool token.
    /// Pool token is defined as the token of the pool that is not USDC or WETH, if the pool is USDC-WETH than token is WETH.
    /// Base token is the other token that is not pool token.
    /// If base token is not USDC, then Constants.ETH_USDC_POOL is used for conversion of the token denominated price.
    /// Behavior for non USDC-WETH pool is undefined.
    /// Query is performed using the uniswap pool oracle functionality (observations buffer) to prevent the price from being affected by flash loans
    /// @param pool the uniswap v3 pool to query
    /// @return Documents the return variables of a contract’s function state variable
    function getMarketTickvsUSDC(IUniswapV3Pool pool)
        internal
        view
        returns (int24)
    {
        (IERC20 refToken, IERC20 assetToken) = getPair(pool);
        // sortedTick = ref / token
        int24 sortedTick = getSortedTick(pool, refToken, assetToken);
        if (refToken != Constants.WETH) {
            // refToken is a stable coin. We assume value of all stable coins is the same. Tokens here: USDC, USDT, DAI
            return sortedTick; // sortedTick = USD / token
        } else {
            // refToken == WETH
            // solhint-disable-next-line var-name-mixedcase
            int24 sortedUSDC_ETH = getSortedTick(
                Constants.ETH_USDC_POOL,
                Constants.USDC,
                Constants.WETH
            );
            // sortedTick = WETH / token
            // sortedTick + sortedUSDC_ETH = (WETH / token) * (USDC / WETH) = USD(C) / token
            return sortedTick + sortedUSDC_ETH;
        }
    }

    function getMarketTickvsUSDCwithUSDCWETHTick(IUniswapV3Pool pool)
        internal
        view
        returns (int24, int24)
    {
        (IERC20 refToken, IERC20 assetToken) = getPair(pool);
        // sortedTick = ref / token
        int24 sortedTick = getSortedTick(pool, refToken, assetToken);
        // solhint-disable-next-line var-name-mixedcase
        int24 sortedUSDC_ETH = getSortedTick(
            Constants.ETH_USDC_POOL,
            Constants.USDC,
            Constants.WETH
        );
        if (refToken != Constants.WETH) {
            // refToken is a stable coin. We assume value of all stable coins is the same. Tokens here: USDC, USDT, DAI
            return (sortedTick, sortedUSDC_ETH); // sortedTick = USD / token
        } else {
            // refToken == WETH
            // sortedTick = WETH / token
            // sortedTick + sortedUSDC_ETH = (WETH / token) * (USDC / WETH) = USDC / token
            return (sortedTick + sortedUSDC_ETH, sortedUSDC_ETH);
        }
    }

    /// @notice gets uniswap tick on a pool sorted such that
    /// returned tick = log_1.0001(price) where price is denominated in provided "denominator"
    /// @dev Uniswap ticks on a pool are between "token0" and "token1" which are always sorted depending on address value.
    /// @dev This function gets tick of given pool using OracleLibrary and possibly inverts (*-1) such that returned tick is as expected
    /// @dev correctness of pool, numerator and denominator is assumed
    /// @param pool the pool
    /// @param numerator one of token0 & token1 of pool
    /// @param denominator one of token0 & token1 of pool but not "numerator"
    /// @return the sorted tick
    function getSortedTick(
        IUniswapV3Pool pool,
        IERC20 numerator,
        IERC20 denominator
    ) internal view returns (int24) {
        int24 timeWeightedTick = OracleLibrary.consult(pool);
        if (numerator > denominator) {
            return timeWeightedTick;
        } else {
            return -timeWeightedTick;
        }
    }

    /// @notice Returns pair of tokens of supplied uniswap pools
    /// sorted such that the first/base token is always USDC, DAI, USDT or WETH.
    /// if both tokens qualify to be a base token then we use the following ordering.
    /// Order (earlier is preferred): USDC, WETH, DAI, USDT
    /// Reverts for pool that is not vs a base token
    /// @param pool the uniswapV3 pool to query
    /// @return base base token (USDC, WETH, DAI or USDT)
    /// @return asset the other token
    function getPair(IUniswapV3Pool pool)
        internal
        view
        returns (IERC20 base, IERC20 asset)
    {
        IERC20 token0 = IERC20(pool.token0());
        IERC20 token1 = IERC20(pool.token1());

        bool found;
        (found, base, asset) = ifOneSort(token0, token1, Constants.USDC);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.WETH);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.DAI);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.USDT);
        if (found) return (base, asset);
        revert("Invalid pool");
    }

    // @dev helper for getPair
    function ifOneSort(
        IERC20 token0,
        IERC20 token1,
        IERC20 search
    )
        private
        pure
        returns (
            bool isOne,
            IERC20 base,
            IERC20 asset
        )
    {
        if (token0 == search) return (true, token0, token1);
        else if (token1 == search) return (true, token1, token0);
        else return (false, IERC20(address(0)), IERC20(address(0)));
    }
}