// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ICollectooorFactory {
    enum CrossChainAction {
        RequestMerkleRoot,
        RequestMerkleRootAtBlock
    }

    struct RequestMerkleRootParams {
        address requester;
        address collectooor;
    }

    struct RequestMerkleRootAtBlockParams {
        address requester;
        address collectooor;
        uint256 blockNumber;
    }

    event CollectooorMasterCopyUpdated(
        address oldMasterCopy,
        address newMasterCopy
    );
    event CollectooorDeployed(address collectooor);
    event MerkleRootSent(
        address requester,
        bytes32 merkleRoot,
        uint256 nodeCount
    );
}