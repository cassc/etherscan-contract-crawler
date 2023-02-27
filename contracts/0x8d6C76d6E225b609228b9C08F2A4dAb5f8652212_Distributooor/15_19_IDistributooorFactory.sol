// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IDistributooorFactory {
    enum CrossChainAction {
        ReceiveMerkleRoot
    }

    struct ReceiveMerkleRootParams {
        /// @notice Original requester of merkle root
        address requester;
        /// @notice Merkle root collector
        address collectooor;
        uint256 blockNumber;
        bytes32 merkleRoot;
        uint256 nodeCount;
    }

    event DistributooorMasterCopyUpdated(
        address oldMasterCopy,
        address newMasterCopy
    );
    event DistributooorDeployed(address distributooor);
    event RaffleChefUpdated(address oldRaffleChef, address newRaffleChef);

    error UnknownConsumer(address consumer);

    /// @notice Request merkle root from an external collectooor
    function requestMerkleRoot(
        uint256 chainId,
        address collectooorFactory,
        address collectooor
    ) external;
}