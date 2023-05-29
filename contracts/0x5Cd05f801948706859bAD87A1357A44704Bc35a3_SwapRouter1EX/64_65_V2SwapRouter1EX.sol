// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/swap-router-contracts/contracts/interfaces/IV2SwapRouter.sol";
import "@uniswap/swap-router-contracts/contracts/base/ImmutableState.sol";
import "@uniswap/swap-router-contracts/contracts/base/PeripheryPaymentsWithFeeExtended.sol";
import "@uniswap/swap-router-contracts/contracts/libraries/Constants.sol";
import "@uniswap/swap-router-contracts/contracts/libraries/UniswapV2Library.sol";
import "./OneExFee.sol";

/// @title Uniswap V2 Swap Router
/// @notice Router for stateless execution of swaps against Uniswap V2
abstract contract V2SwapRouter1EX is
    IV2SwapRouter,
    ImmutableState,
    PeripheryPaymentsWithFeeExtended,
    OneExFee
{
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    function _swap(address[] memory path, address _to) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address currentPairAddress = UniswapV2Library.pairFor(
                factoryV2,
                input,
                output
            );
            // ******
            {
                if (i > 0) {
                    uint256 amountInReceived = IERC20(input).balanceOf(address(this));

                    uint256 oneExFee = oneExFeePercent != 0
                        ? FullMath.mulDivRoundingUp(
                            amountInReceived,
                            3 * oneExFeePercent,
                            1e5
                        )
                        : 0;
                    if (oneExFee > 0)
                        pay(input, address(this), oneExFeeCollector, oneExFee);

                    pay(
                        input,
                        address(this),
                        currentPairAddress,
                        amountInReceived - oneExFee
                    );
                }
            }
            // ******
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(currentPairAddress);
            uint256 amountInput;
            uint256 amountOutput;
            // scope to avoid stack too deep errors
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = UniswapV2Library.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? address(this) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @inheritdoc IV2SwapRouter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountOut) {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            amountIn = IERC20(path[0]).balanceOf(address(this));
        }

        // Calculate and transfer 1EX fee
        uint256 oneExFee = oneExFeePercent != 0
            ? FullMath.mulDivRoundingUp(amountIn, 3 * oneExFeePercent, 1e5)
            : 0;
        if (oneExFee > 0)
            pay(
                path[0],
                hasAlreadyPaid ? address(this) : msg.sender,
                oneExFeeCollector,
                oneExFee
            );

        pay(
            path[0],
            hasAlreadyPaid ? address(this) : msg.sender,
            UniswapV2Library.pairFor(factoryV2, path[0], path[1]),
            amountIn - oneExFee
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swap(path, to);

        amountOut = IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);

        require(amountOut >= amountOutMin, "Too little received");
    }

    /// @inheritdoc IV2SwapRouter
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable override returns (uint256 amountIn) {
        amountIn = getAmountsIn(factoryV2, amountOut, path)[0];
        require(amountIn <= amountInMax, "Too much requested");

        // Calculate and transfer 1EX fee
        uint256 oneExFee = oneExFeePercent != 0
            ? FullMath.mulDivRoundingUp(amountIn, 3 * oneExFeePercent, 1e5)
            : 0;
        if (oneExFee > 0) pay(path[0], msg.sender, oneExFeeCollector, oneExFee);

        pay(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factoryV2, path[0], path[1]),
            amountIn - oneExFee
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        _swap(path, to);
    }

    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2);
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
                factory,
                path[i - 1],
                path[i]
            );

            uint256 amountIn = UniswapV2Library.getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut
            );

            amounts[i - 1] = FullMath.mulDivRoundingUp(
                amountIn,
                1e5,
                1e5 - 3 * oneExFeePercent
            );
        }
    }
}