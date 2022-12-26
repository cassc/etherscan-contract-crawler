// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRango {
    /// Structs ///
    struct BridgeDataXY {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    /// Events ///

}