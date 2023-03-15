// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {FeeCollector} from "contracts/src/utils/FeeCollector.sol";
import {ENSHelper} from "contracts/src/utils/ENSHelper.sol";
import {StringHelper} from "contracts/src/utils/StringHelper.sol";
import {ITelepathyRouter} from "telepathy-contracts/amb/interfaces/ITelepathy.sol";
import {TelepathyHandler} from "telepathy-contracts/amb/interfaces/TelepathyHandler.sol";

/// @title CrossChainMailer
/// @author Succinct Labs
/// @notice An example contract for sending messages to other chains, using the TelepathyRouter.
/// @dev The FeeCollector is for discouraging spam on non-mainnet chains.
contract CrossChainMailer is FeeCollector, ENSHelper {
    /// @notice The TelepathyRouter contract, which sends messages to other chains.
    ITelepathyRouter public telepathyRouter;

    constructor(address _telepathyRouter) {
        telepathyRouter = ITelepathyRouter(_telepathyRouter);
    }

    /// @notice Sends a message to a destination mailbox.
    /// @param _destinationChainId The chain ID where the destination CrossChainMailbox.
    /// @param _destinationMailbox The address of the destination CrossChainMailbox.
    /// @param _message The message to send.
    function sendMail(uint32 _destinationChainId, address _destinationMailbox, bytes memory _message)
        external
        payable
    {
        if (msg.value < fee) {
            revert InsufficientFee(msg.value, fee);
        }
        string memory data = StringHelper.formatMessage(_message, msg.sender.balance, ENSHelper.getName(msg.sender));
        telepathyRouter.send(_destinationChainId, _destinationMailbox, bytes(data));
    }
}

/// @title CrossChainMailbox
/// @author Succinct Labs
/// @notice An example contract for receiving messages from other chains, using the TelepathyHandler.
contract CrossChainMailbox is TelepathyHandler {
    string[] public messages;

    event MessageReceived(uint32 indexed sourceChainId, address indexed sourceAddress, string message);

    constructor(address _telepathyRouter) TelepathyHandler(_telepathyRouter) {}

    function handleTelepathyImpl(uint32 _sourceChainId, address _sourceAddress, bytes memory _message)
        internal
        override
    {
        messages.push(string(_message));
        emit MessageReceived(_sourceChainId, _sourceAddress, string(_message));
    }

    function messagesLength() external view returns (uint256) {
        return messages.length;
    }
}