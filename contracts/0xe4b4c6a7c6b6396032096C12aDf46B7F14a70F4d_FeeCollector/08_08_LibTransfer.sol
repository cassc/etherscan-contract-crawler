// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Library for functions related to transfers.
library LibTransfer {
    /// @notice Error thrown when sending ether fails.
    /// @param recipient The address that could not receive the ether.
    error FailedToSendEther(address recipient);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);

    /// @notice Sends ether to an address, forwarding all available gas and reverting on errors.
    /// @param recipient The recipient of the ether.
    /// @param amount The amount of ether to send in base units.
    function sendEther(address payable recipient, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert FailedToSendEther(recipient);
    }

    /// @notice Sends an ERC20 token to an address and reverts if the transfer returns false.
    /// @dev Wrapper for {IERC20-transfer}.
    /// @param to The recipient of the tokens.
    /// @param token The address of the token to send.
    /// @param amount The amount of the token to send in base units.
    function sendToken(address to, address token, uint256 amount) internal {
        if (!IERC20(token).transfer(to, amount)) revert TransferFailed(msg.sender, address(this));
    }

    /// @notice Sends an ERC20 token to an address from another address and reverts if transferFrom returns false.
    /// @dev Wrapper for {IERC20-transferFrom}.
    /// @dev The contract needs to be approved using the {IERC20-approve} function to move the tokens.
    /// @param to The recipient of the tokens.
    /// @param from The source of the tokens.
    /// @param token The address of the token to send.
    /// @param amount The amount of the token to send in base units.
    function sendTokenFrom(address to, address from, address token, uint256 amount) internal {
        if (!IERC20(token).transferFrom(from, to, amount)) revert TransferFailed(msg.sender, address(this));
    }
}