// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AbstractPayments.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SwapPath.sol";

/// @title Uniswap V2 Swap Router
/// @notice A stateless execution router adapted for the Uniswap V2 protocol
abstract contract UniswapV2Router is IUniswapV2Router, AbstractPayments {
    using SwapPath for bytes;
    address public immutable uniswapV2PoolFactory;

    constructor(address _uniswapV2PoolFactory) {
        uniswapV2PoolFactory = _uniswapV2PoolFactory;
    }

    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    function _swap(address[] memory path, address _to) private {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) {
                (address input, address output) = (path[i], path[i + 1]);
                address to = i < path.length - 2
                    ? UniswapV2Library.pairFor(uniswapV2PoolFactory, output, path[i + 2])
                    : _to;
                _swapOnce(input, output, to);
            }
        }
    }

    function _swapOnce(address input, address output, address recipient) private {
        (address token0, ) = UniswapV2Library.sortTokens(input, output);
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapV2PoolFactory, input, output));
        uint256 amountInput;
        uint256 amountOutput;
        // scope to avoid stack too deep errors
        {
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));

        pair.swap(amount0Out, amount1Out, recipient, new bytes(0));
    }

    function uniswapV2ExactInputInternal(
        uint256 amountIn,
        bytes memory path,
        address payer,
        address recipient
    ) internal returns (uint256 amountOut) {
        (address input, address output, ) = path.decodeFirstGrid();
        pay(input, payer, UniswapV2Library.pairFor(uniswapV2PoolFactory, input, output), amountIn);
        uint256 balanceBefore = IERC20(output).balanceOf(recipient);
        _swapOnce(input, output, recipient);
        amountOut = IERC20(output).balanceOf(recipient) - balanceBefore;
    }

    /// @inheritdoc IUniswapV2Router
    function uniswapV2ExactInput(
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountOut) {
        pay(path[0], _msgSender(), UniswapV2Library.pairFor(uniswapV2PoolFactory, path[0], path[1]), amountIn);

        // allows swapping to the router address with address 0
        to = to == address(0) ? address(this) : to;

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swap(path, to);

        amountOut = IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore;
        // UV2R_TLR: too little received
        require(amountOut >= amountOutMinimum, "UV2R_TLR");
    }

    /// @inheritdoc IUniswapV2Router
    function uniswapV2ExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountIn) {
        amountIn = UniswapV2Library.getAmountsIn(uniswapV2PoolFactory, amountOut, path)[0];
        // UV2R_TMR: Too much requested
        require(amountIn <= amountInMaximum, "UV2R_TMR");

        pay(path[0], _msgSender(), UniswapV2Library.pairFor(uniswapV2PoolFactory, path[0], path[1]), amountIn);

        // allows swapping to the router address with address 0
        to = to == address(0) ? address(this) : to;

        _swap(path, to);
    }
}