// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGatekeeper {
    struct Gate {
        bool enabled;
        uint8 stageIndex; // stage from [0-3] (range defined within GameRegistry)
        uint32 claimedCount; // # of claims already happened
        uint32 maxClaimable; // # of claims per gate
        bytes32 gateRoot;
        uint256 activeAt; // timestamp when active.
    }

    /// @notice validate how much a player can claim for a particular token and gate.
    /// @param bundleId the ID of the bundle in the game.
    /// @param index the gate index the player is claiming
    /// @param amount the exact number of tokens a player wants to claim
    /// @param proof merkle proof associated with the amount
    /// @return claimAmount the number of tokens available for claim
    function calculateClaimable(
        uint256 bundleId,
        uint256 index,
        address player,
        uint32 amount,
        bytes32[] calldata proof
    ) external returns (uint32 claimAmount);

    /// @notice Validates proof -- does not modify the state.
    /// @param bundleId the ID of the bundle in the game.
    /// @param index the gate index the player is claiming
    /// @param amount the exact number of tokens a player wants to claim
    /// @param proof merkle proof associated with the amount
    /// @return validProof boolean representing the validity of the proof given
    function validateProof(uint256 bundleId, uint256 index, address player, uint32 amount, bytes32[] calldata proof)
        external
        returns (bool validProof);

    // Permissioned Methods -- Should not be open for everyone to call.

    /// @notice Update internal accounting, can only be called by a game instance.
    /// @param bundleId the ID of the bundle in the game.
    /// @param numClaimed increases gate claimed count by this value
    /// @param gateId the gate index the player is claiming
    /// @param proof consumes the proof that is used by the claim
    function addClaimed(uint256 bundleId, uint256 gateId, uint32 numClaimed, bytes32[] calldata proof) external;

    /// @notice adds a gate to the gates array, should only be called by a gameAdmin
    /// @param bundleId the id of bundle in the GameInstance
    /// @param root_ merkle root associated with the gate
    /// @param maxClaimable_ free claimable limit for the gate being added
    /// @param stageIndex_ the corresponds to the stage array within the gameRegistry
    function addGate(uint256 bundleId, bytes32 root_, uint32 maxClaimable_, uint8 stageIndex_) external;

    /// @notice Called by a game when a game is started to set times of gates opening.
    /// @dev Uses the stages array within GameRegistry to program gate openings. Will revert if there no gate associated with the bundle
    function startGatesForBundle(uint256 bundleId) external;
}