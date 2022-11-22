// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./AsyncInformationProcessor.sol";

contract BrewlabsHomeAMB is AsyncInformationProcessor {
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );

    function emitEventOnMessageRequest(bytes32 messageId, bytes memory encodedData) internal override{
        emit UserRequestForSignature(messageId, encodedData);
    }

    function emitEventOnMessageProcessed(
        address sender,
        address executor,
        bytes32 messageId,
        bool status
    ) internal override {
        emit AffirmationCompleted(sender, executor, messageId, status);
    }
}