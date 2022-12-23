// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "borrow/interfaces/IAngleRouterSidechain.sol";
import "borrow/interfaces/ICoreBorrow.sol";
import "borrow/interfaces/external/uniswap/IUniswapRouter.sol";
import "../../interfaces/IBorrowStaker.sol";

import "borrow/swapper/Swapper.sol";

/// @title BaseLevSwapper
/// @author Angle Labs, Inc.
/// @notice Swapper contract facilitating interactions with Angle VaultManager contracts, notably
/// liquidation and leverage transactions
/// @dev This base implementation is for tokens like LP tokens which are not natively supported by 1inch
/// and need some wrapping/unwrapping
abstract contract BaseLevSwapper is Swapper {
    using SafeERC20 for IERC20;

    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) Swapper(_core, _uniV3Router, _oneInch, _angleRouter) {
        if (address(angleStaker()) != address(0))
            angleStaker().asset().safeIncreaseAllowance(address(angleStaker()), type(uint256).max);
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @inheritdoc Swapper
    /// @param data Encoded data giving specific instruction to the bundle tx
    /// @dev The amountOut is unused so left as 0 in the case of a deleverage transaction
    /// @dev All token transfers must have been done beforehand
    /// @dev This function can support multiple swaps to get a desired token
    function _swapLeverage(bytes memory data) internal override returns (uint256 amountOut) {
        bool leverage;
        address to;
        bytes[] memory oneInchPayloads;
        (leverage, to, data) = abi.decode(data, (bool, address, bytes));
        if (leverage) {
            (oneInchPayloads, data) = abi.decode(data, (bytes[], bytes));
            // After sending all your tokens you have the possibility to swap them through 1inch
            // For instance when borrowing on Angle you receive agEUR, but may want to be LP on
            // the 3Pool, you can then swap 1/3 of the agEUR to USDC, 1/3 to USDT and 1/3 to DAI
            // before providing liquidity
            // These swaps are easy to anticipate as you know how many tokens have been sent when querying the 1inch API
            _multiSwap1inch(oneInchPayloads);
            // Hook to add liquidity to the underlying protocol
            amountOut = _add(data);
            // Deposit into the AngleStaker
            angleStaker().deposit(amountOut, to);
        } else {
            uint256 toUnstake;
            uint256 toRemove;
            IERC20[] memory sweepTokens;
            (toUnstake, toRemove, sweepTokens, oneInchPayloads, data) = abi.decode(
                data,
                (uint256, uint256, IERC20[], bytes[], bytes)
            );
            // Should transfer the token to the contract this will claim the rewards for the current owner of the wrapper
            angleStaker().withdraw(toUnstake, address(this), address(this));
            _remove(toRemove, data);
            // Taking the same example as in the `leverage` side, you can withdraw USDC, DAI and USDT while wanting to
            // to repay a debt in agEUR so you need to do a multiswap.
            // These swaps are not easy to anticipate the amounts received depend on the deleverage action which can be chaotic
            // Very often, it's better to swap a lower bound and then sweep the tokens, even though it's not the most efficient
            // thing to do
            _multiSwap1inch(oneInchPayloads);
            // After the swaps and/or the deleverage we can end up with useless tokens for repaying a debt and therefore let the
            // possibility to send it wherever
            _sweep(sweepTokens, to);
        }
    }

    /// @notice Allows to do an arbitrary number of swaps using 1inch API
    /// @param data Encoded info to execute the swaps from `_swapOn1inch`
    function _multiSwap1inch(bytes[] memory data) internal {
        uint256 dataLength = data.length;
        for (uint256 i; i < dataLength; ++i) {
            (address inToken, uint256 minAmount, bytes memory payload) = abi.decode(data[i], (address, uint256, bytes));
            uint256 amountOut = _swapOn1inch(IERC20(inToken), payload);
            // We check the slippage in this case as `swap()` will only check it for the `outToken`
            if (amountOut < minAmount) revert TooSmallAmountOut();
        }
    }

    /// @notice Sweeps tokens from the contract
    /// @param tokensOut Token to sweep
    /// @param to Address to which tokens should be sent
    function _sweep(IERC20[] memory tokensOut, address to) internal {
        uint256 tokensOutLength = tokensOut.length;
        for (uint256 i; i < tokensOutLength; ++i) {
            uint256 balanceToken = tokensOut[i].balanceOf(address(this));
            if (balanceToken != 0) {
                tokensOut[i].safeTransfer(to, balanceToken);
            }
        }
    }

    // ========================= EXTERNAL VIRTUAL FUNCTIONS ========================

    /// @notice Token used as collateral on the borrow module, which wraps the `true` collateral
    function angleStaker() public view virtual returns (IBorrowStaker);

    // ========================= INTERNAL VIRTUAL FUNCTIONS ========================

    /// @notice Implements the bundle transaction to increase exposure to a token
    /// @param data Encoded data giving specific instruction to the bundle tx
    function _add(bytes memory data) internal virtual returns (uint256 amountOut);

    /// @notice Implements the bundle transaction to decrease exposure to a token
    /// @param toRemove Amount of tokens to remove
    /// @param data Encoded data giving specific instruction to the bundle tx
    function _remove(uint256 toRemove, bytes memory data) internal virtual returns (uint256 amount);
}