// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Swapper Flash Callback
/// @author 0xSplits
/// @notice Callback for `Swapper#flash`
/// @dev any contract that calls `Swapper#flash` must implement this interface.
/// Inspired by IUniswapV3FlashCallback
interface ISwapperFlashCallback {
    /// Called to `msg.sender` in `Swapper#flash` after transferring `quoteParams`.
    /// @dev In the implementation you must complete the flash swap.
    /// If `tokenToBeneficiary` is ETH, you must deposit `amountToBeneficiary` via `Swapper#payback`.
    /// If `tokenToBeneficiary` is an ERC20, you must use approve Swapper to transfer `amountToBeneficiary`.
    /// The caller of this method will use token = address(0) to refer to ETH.
    /// @param tokenToBeneficiary The token due to the `beneficiary` by the end of `#flash`
    /// @param amountToBeneficiary The amount of `tokenToBeneficiary` due to the `beneficiary` by the end of `#flash`
    /// @param data Any `data` passed through by `msg.sender` of `Swapper#flash`
    function swapperFlashCallback(address tokenToBeneficiary, uint256 amountToBeneficiary, bytes calldata data)
        external;
}