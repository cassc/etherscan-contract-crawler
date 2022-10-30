// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./SwapHelperUniswap.sol";
import "./SwapHelperBalancer.sol";

/// @title Contains logic facilitating swapping using Uniswap / Balancer
abstract contract SwapHelper is SwapHelperBalancer, SwapHelperUniswap {
    using BytesLib for bytes;

    /**
     * @notice Sets initial values
     * @param _uniswapRouter Uniswap router address
     * @param _WETH WETH token address
     */
    constructor(ISwapRouter02 _uniswapRouter, address _WETH)
        SwapHelperUniswap(_uniswapRouter, _WETH)
        SwapHelperBalancer()
    {}

    /**
     * @notice Approve reward token and swap the `amount` to a strategy underlying asset
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param swapData Swap details showing the path of the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _approveAndSwap(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        SwapData calldata swapData
    ) internal virtual returns (uint256) {
        // If first byte is les or equal to 6, we swap via the Uniswap
        if (swapData.path.toUint8(0) <= 6) {
            return _approveAndSwapUniswap(from, to, amount, swapData);
        }
        return _approveAndSwapBalancer(from, to, amount, swapData);
    }
}