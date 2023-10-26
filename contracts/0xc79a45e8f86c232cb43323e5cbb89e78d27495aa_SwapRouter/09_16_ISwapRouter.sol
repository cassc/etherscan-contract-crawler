// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwapRouter {
    struct SwapRequest {
        IERC20 srcToken; // Source token address
        IERC20 dstToken; // Destination token address
        uint256 amountIn; // Source token amount to swap
        uint256 amountMinSpend; // Minimum token amount to be swapped by aggregator.
        //If this is lower than amountIn, it will skip dex aggregator swap.
        uint256 amountOutMin; // Minimum output amount in desitnation token.
        bool useParaswap; // Flag to use paraswap or not.
        bytes paraswapData; // Paraswap calldata
        DataTypes.SplitSwapInfo[] splitSwapData; // Split swap data array for using several dex aggregators
        uint256[] distribution; // internal swap params at uni v2 like amms.
        bool raiseError; // true to revert, false to continue without reverting.
    }

    /**
     * Swap source token to destination token by dex aggreagors and internal swap.
     * Sometimes, we couldn't swap all src token amount. This happens when dex aggreagator
     * payload amount is lower than amountIn.
     * @param swapRequest SwapRequest struct param
     * @return unspent unswapped source token amount
     * @return returnAmount received destination token amount
     */
    function swap(SwapRequest memory swapRequest)
        external
        payable
        returns (uint256 unspent, uint256 returnAmount);
}