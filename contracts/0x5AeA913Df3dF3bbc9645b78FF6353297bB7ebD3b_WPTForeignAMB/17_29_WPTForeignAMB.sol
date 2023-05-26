// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./BasicForeignAMB.sol";

contract WPTForeignAMB is BasicForeignAMB {
    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    function emitEventOnMessageRequest(bytes32 messageId, bytes memory encodedData) internal override {
        emit UserRequestForAffirmation(messageId, encodedData);
    }

    function emitEventOnMessageProcessed(
        address sender,
        address executor,
        bytes32 messageId,
        bool status
    ) internal override {
        emit RelayedMessage(sender, executor, messageId, status);
    }
}