// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.18;

/// @dev The ERC3156 spec mandates this hash be returned by `onFlashLoan` if it
/// succeeds.
bytes32 constant ON_FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32);
}