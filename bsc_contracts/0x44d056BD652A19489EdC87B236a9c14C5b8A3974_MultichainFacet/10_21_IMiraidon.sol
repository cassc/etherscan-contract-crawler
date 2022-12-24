// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMiraidon {
    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 minUSDAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    event MiraidonTransferStarted(IMiraidon.BridgeData bridgeData);
}