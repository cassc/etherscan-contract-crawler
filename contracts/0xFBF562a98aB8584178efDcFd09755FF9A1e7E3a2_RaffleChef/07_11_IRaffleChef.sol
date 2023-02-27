// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IRaffleChef {
    event RaffleCreated(uint256 indexed raffleId);
    event RaffleCommitted(uint256 indexed raffleId);

    error RaffleNotRolled(uint256 raffleId);
    error InvalidCommitment(
        uint256 raffleId,
        bytes32 merkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        uint256 randomness,
        string provenance
    );
    error Unauthorised(address unauthorisedUser);
    error StartingRaffleIdTooLow(uint256 raffleId);
    error InvalidProof(bytes32 leaf, bytes32[] proof);

    /// @dev Descriptive state of a raffle based on its variables that are set/unset
    enum RaffleState {
        /// @dev Default state
        Unknown,
        /// @dev Done
        Committed
    }

    /// @notice Structure of every raffle; presence of certain elements indicate the raffle state
    struct Raffle {
        bytes32 participantsMerkleRoot;
        uint256 nParticipants;
        uint256 nWinners;
        uint256 randomSeed;
        address owner;
        string provenance;
    }

    /// @notice Publish a commitment (the merkle root of the finalised participants list, and
    ///     the number of winners to draw, and the random seed). Only call this function once
    ///     the random seed and list of raffle participants has finished being collected.
    /// @param participantsMerkleRoot Merkle root constructed from finalised participants list
    /// @param nWinners Number of winners to draw
    /// @param provenance IPFS CID of this raffle's provenance including full participants list
    /// @param randomness Random seed for the raffle
    /// @return Raffle ID that can be used to lookup the raffle results, when
    ///     the raffle is finalised.
    function commit(
        bytes32 participantsMerkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        string calldata provenance,
        uint256 randomness
    ) external returns (uint256);

    /// @notice Verify that an account is in the winners list for a specific raffle
    ///     using a merkle proof and the raffle's previous public commitments. This is
    ///     a view-only function that does not record if a winner has already claimed
    ///     their win; that is left up to the caller to handle.
    /// @param raffleId ID of the raffle to check against
    /// @param leafHash Hash of the leaf value that represents the participant
    /// @param proof Merkle subproof (hashes)
    /// @param originalIndex Original leaf index in merkle tree, part of merkle proof
    /// @return isWinner true if claiming account is indeed a winner
    /// @return permutedIndex winning (shuffled) index
    function verifyRaffleWinner(
        uint256 raffleId,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 originalIndex
    ) external view returns (bool isWinner, uint256 permutedIndex);

    /// @notice Get an existing raffle
    /// @param raffleId ID of raffle to get
    /// @return raffle data, if it exists
    function getRaffle(uint256 raffleId) external view returns (Raffle memory);

    /// @notice Get the current state of raffle, given a `raffleId`
    /// @param raffleId ID of raffle to get
    /// @return See {RaffleState} enum
    function getRaffleState(
        uint256 raffleId
    ) external view returns (RaffleState);
}