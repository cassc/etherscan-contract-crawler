// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IDistributooor {
    /// @notice Receive a merkle root from a trusted source.
    /// @param srcChainId Chain ID where the Merkle collector lives
    /// @param srcCollector Contract address of Merkle collector
    /// @param blockNumber Block number at which the Merkle root was calculated
    /// @param merkleRoot Merkle root of participants
    /// @param nParticipants Number of participants in the merkle tree
    function receiveParticipantsMerkleRoot(
        uint256 srcChainId,
        address srcCollector,
        uint256 blockNumber,
        bytes32 merkleRoot,
        uint256 nParticipants
    ) external;

    event MerkleRootReceived(
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 blockNumber
    );

    event ERC721Received(address nftContract, uint256 tokenId);
    event ERC1155Received(address nftContract, uint256 tokenId, uint256 amount);
    event ERC721Reclaimed(address nftContract, uint256 tokenId);
    event ERC1155Reclaimed(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    );
    event Finalised(
        uint256 raffleId,
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 randomness,
        string provenance
    );

    error Unauthorised(address caller);
    error MerkleRootRejected(
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 blockNumber
    );
    error InvalidSignature(
        bytes signature,
        address expectedSigner,
        address recoveredSigner
    );
    error InvalidRequestId(uint256 requestId);
    error MerkleRootNotReady(uint256 requestId);
    error AlreadyFinalised(uint256 raffleId);
}