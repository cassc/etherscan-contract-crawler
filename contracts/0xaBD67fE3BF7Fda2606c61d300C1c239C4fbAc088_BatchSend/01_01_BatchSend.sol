// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Batch send Ether to multiple addresses.
/// @author jalil.eth & backseats.eth
contract BatchSend {

    /// @dev Inform DAPPs of a failed transfer recipient.
    event FailedTransfer(address indexed recipient, uint256 amount);

    /// @dev Error for bad input.
    error ArrayLengthMismatch();

    /// @notice Send ether to many addresses.
    /// @param recipients The addresses that should receive funds.
    /// @param amounts How much wei to send to each address.
    function send(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public payable {
        uint256 count = recipients.length;
        if (count != amounts.length) revert ArrayLengthMismatch();

        uint256 failedAmount;
        for (uint i; i < count;) {
            (bool success,) = payable(recipients[i]).call{value: amounts[i]}("");

            // Keep track of failed transfers
            if (!success) {
                failedAmount += amounts[i];

                emit FailedTransfer(recipients[i], amounts[i]);
            }

            unchecked { ++i; }
        }

        // If anything failed to send, refund the msg.sender
        if (failedAmount > 0) payable(msg.sender).transfer(failedAmount);
    }
}

// LGTM

// <3 ty

// anytime man