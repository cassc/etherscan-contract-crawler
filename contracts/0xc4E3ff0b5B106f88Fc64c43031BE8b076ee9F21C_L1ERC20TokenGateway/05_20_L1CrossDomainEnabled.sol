// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import {IInbox} from "./interfaces/IInbox.sol";
import {IBridge} from "./interfaces/IBridge.sol";
import {IOutbox} from "./interfaces/IOutbox.sol";

/// @author psirex
/// @notice A helper contract to simplify Ethereum to Arbitrum communication process process
///     via Retryable Tickets
contract L1CrossDomainEnabled {
    /// @notice Address of the Arbitrum's Inbox contract
    IInbox public immutable inbox;

    /// @param inbox_ Address of the Arbitrum's Inbox contract
    constructor(address inbox_) {
        inbox = IInbox(inbox_);
    }

    /// @dev Properties required to create RetryableTicket
    /// @param maxGas Gas limit for immediate L2 execution attempt
    /// @param callValue Call-value for L2 transaction
    /// @param gasPriceBid L2 Gas price bid for immediate L2 execution attempt
    /// @param maxSubmissionCost Amount of ETH allocated to pay for the base submission fee
    struct CrossDomainMessageOptions {
        uint256 maxGas;
        uint256 callValue;
        uint256 gasPriceBid;
        uint256 maxSubmissionCost;
    }

    /// @notice Creates a Retryable Ticket via Inbox.createRetryableTicket function using
    ///     the provided arguments
    /// @param sender_ Address of the sender of the message
    /// @param recipient_ Address of the recipient of the message on the L2 chain
    /// @param data_ Data passed to the recipient_ in the message
    /// @param msgOptions_ Instance of the `CrossDomainMessageOptions` struct
    /// @return seqNum Unique id of created Retryable Ticket.
    function sendCrossDomainMessage(
        address sender_,
        address recipient_,
        bytes memory data_,
        CrossDomainMessageOptions memory msgOptions_
    ) internal returns (uint256 seqNum) {
        if (msgOptions_.maxSubmissionCost == 0) {
            revert ErrorNoMaxSubmissionCost();
        }

        uint256 minEthValue = msgOptions_.callValue +
            msgOptions_.maxSubmissionCost +
            (msgOptions_.maxGas * msgOptions_.gasPriceBid);

        if (msg.value < minEthValue) {
            revert ErrorETHValueTooLow();
        }

        seqNum = inbox.createRetryableTicket{value: msg.value}(
            recipient_,
            msgOptions_.callValue,
            msgOptions_.maxSubmissionCost,
            sender_,
            sender_,
            msgOptions_.maxGas,
            msgOptions_.gasPriceBid,
            data_
        );

        emit TxToL2(sender_, recipient_, seqNum, data_);
    }

    /// @notice Validates that transaction was initiated by the crossDomainAccount_ address from
    ///     the L2 chain
    modifier onlyFromCrossDomainAccount(address crossDomainAccount_) {
        address bridge = inbox.bridge();

        // a message coming from the counterpart gateway was executed by the bridge
        if (msg.sender != bridge) {
            revert ErrorUnauthorizedBridge();
        }

        address l2ToL1Sender = IOutbox(IBridge(bridge).activeOutbox())
            .l2ToL1Sender();

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        if (l2ToL1Sender != crossDomainAccount_) {
            revert ErrorWrongCrossDomainSender();
        }
        _;
    }

    event TxToL2(
        address indexed from,
        address indexed to,
        uint256 indexed seqNum,
        bytes data
    );

    error ErrorETHValueTooLow();
    error ErrorUnauthorizedBridge();
    error ErrorNoMaxSubmissionCost();
    error ErrorWrongCrossDomainSender();
}