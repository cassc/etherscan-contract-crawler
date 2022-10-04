// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {IUniswapV2Router01} from "./interfaces/uniswapv2/IUniswapV2Router01.sol";
import {IUniswapV2Pair} from "./interfaces/uniswapv2/IUniswapV2Pair.sol";

/**
 * @title PriceAggregatorV2
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Finds the TOKEN/WETH pair and returns proporitional pricing relative
 *         to another LP pair. Only WETH supported.
 */
contract PriceAggregatorV2 {
    address public constant WETH_CONTRACT =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Uniswap V2 Router
    IUniswapV2Router01 public immutable uniswapV2Router;

    /// @notice Sushiswap V2 Router
    IUniswapV2Router01 public immutable sushiswapRouter;

    /// @notice Must be non-zero amount
    error NonZeroNumberRequired();

    /// @notice Not a WETH pair on either side
    error WrappedEtherPairNotFound();

    constructor(
        IUniswapV2Router01 uniswapV2Router_,
        IUniswapV2Router01 sushiswapRouter_
    ) {
        uniswapV2Router = uniswapV2Router_;
        sushiswapRouter = sushiswapRouter_;
    }

    /**
     * @notice Get the price pair for a UniSwapV2 or SushiSwapV2 pair.
     * @param pair The UniSwap/SushiSwap pair address
     * @param amount Amount to receive a quote (1e18 will return the price of 1 token)
     */
    function getPairPriceV2(IUniswapV2Pair pair, uint256 amount)
        public
        view
        returns (uint256 quote)
    {
        if (pair.token0() != WETH_CONTRACT && pair.token1() != WETH_CONTRACT) {
            revert WrappedEtherPairNotFound();
        }
        address factory = pair.factory();
        IUniswapV2Router01 router;
        if (factory == sushiswapRouter.factory()) {
            router = sushiswapRouter;
        } else if (factory == uniswapV2Router.factory()) {
            router = uniswapV2Router;
        }
        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        if (pair.token1() == WETH_CONTRACT) {
            quote = router.quote(amount, reserveA, reserveB);
        } else {
            quote = router.quote(amount, reserveB, reserveA);
        }
        if (quote == 0) {
            revert NonZeroNumberRequired();
        }
    }

    /**
     * @notice Get the price of two pairs, relative to the secondary token.
     * @param amount Amount of the primary token to exchange for secondary token
     * @param markup Additional markup (10000 = %100.00)
     * @param primary The primary token pair
     * @param secondary The secondary token pair
     * @param amount Returns the secondary token equivalent
     */
    function findPairEquivalentToPairV2(
        uint256 amount,
        uint256 markup,
        IUniswapV2Pair primary,
        IUniswapV2Pair secondary
    ) public view returns (uint256) {
        uint256 pair1 = getPairPriceV2(primary, amount);
        uint256 pair2 = getPairPriceV2(secondary, amount);
        if (pair2 == 0) {
            revert NonZeroNumberRequired();
        }
        return (((pair1 * amount) / pair2) * (10000 + markup)) / 10000;
    }
}