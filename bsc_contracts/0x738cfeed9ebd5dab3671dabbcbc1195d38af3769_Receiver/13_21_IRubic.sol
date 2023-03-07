// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRubic {
    /// Structs ///

    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        address integrator;
        address referrer;
        address sendingAssetId;
        address receivingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    /// Events ///

    event RubicTransferStarted(IRubic.BridgeData bridgeData);

    event RubicTransferCompleted(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );

    event RubicTransferRecovered(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );
}