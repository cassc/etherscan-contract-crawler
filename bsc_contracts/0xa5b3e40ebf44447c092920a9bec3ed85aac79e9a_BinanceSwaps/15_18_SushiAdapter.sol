// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "sushiswap/protocols/sushixswap/contracts/libraries/UniswapV2Library.sol";

/// @title SushiLegacyAdapter
/// @notice Adapter for functions used to swap using Sushiswap Legacy AMM.
abstract contract SushiAdapter {
    using SafeERC20 for IERC20;

    /// @notice Sushiswap Legacy AMM Factory
    address public factory;

    /// @notice Sushiswap Legacy AMM PairCodeHash
    bytes32 public pairCodeHash;

    struct SushiParams {
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        bool sendTokens;
    }

    constructor(address _factory, bytes32 _pairCodeHash) {
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    function _swapExactTokensForTokens(SushiParams memory params) internal returns (uint256 amountOut) {
        params.amountIn = params.amountIn == 0 ? IERC20(params.path[0]).balanceOf(address(this)) : params.amountIn;
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, params.amountIn, params.path, pairCodeHash);
        amountOut = amounts[amounts.length - 1];

        require(amountOut >= params.amountOutMin, "insufficient-amount-out");

        /// @dev force sends token to the first pair if not already sent
        if (params.sendTokens) {
            IERC20(params.path[0]).safeTransfer(
                UniswapV2Library.pairFor(factory, params.path[0], params.path[1], pairCodeHash),
                params.amountIn
            );
        }
        _swap(amounts, params.path, address(this));
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to =
                i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2], pairCodeHash) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output, pairCodeHash)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
}