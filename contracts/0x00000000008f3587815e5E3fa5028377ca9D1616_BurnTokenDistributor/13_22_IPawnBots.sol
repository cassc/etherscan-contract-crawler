// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IPawnBots
/// @author Hifi
interface IPawnBots {
    /// ENUMS ///

    enum MintPhase {
        PRIVATE,
        PUBLIC
    }

    /// EVENTS ///

    /// @notice Emitted when unsold tokens are burned.
    /// @param burnAmount The amount of tokens burned.
    event BurnUnsold(uint256 burnAmount);

    /// @notice Emitted when a user account mints new tokens.
    /// @param minter The minter account address.
    /// @param mintAmount The amount of minted tokens.
    /// @param phase The mint phase.
    event Mint(address indexed minter, uint256 mintAmount, MintPhase phase);

    /// @notice Emitted when reserved tokens are minted.
    /// @param reserveAmount The amount of reserved tokens minted.
    /// @param recipient The recipient of reserved tokens minted.
    event Reserve(uint256 reserveAmount, address recipient);

    /// @notice Emitted when the collection metadata is revealed.
    event Reveal();

    /// @notice Emitted when base URI is set.
    /// @param newBaseURI The new base URI.
    event SetBaseURI(string newBaseURI);

    /// @notice Emitted when the per-account mint limit is set.
    /// @param newMaxPerAccount The new per-account mint limit.
    event SetMaxPerAccount(uint256 newMaxPerAccount);

    /// @notice Emitted when Merkle root is set.
    /// @param newMerkleRoot The new Merkle root.
    event SetMerkleRoot(bytes32 newMerkleRoot);

    /// @notice Emitted when the mint state is set.
    /// @param newMintActive The new mint state.
    event SetMintActive(bool newMintActive);

    /// @notice Emitted when the mint phase is set.
    /// @param newMintPhase The new mint phase.
    event SetMintPhase(MintPhase newMintPhase);

    /// @notice Emitted when provenance hash is set.
    /// @param newProvenanceHash The new provenance hash.
    event SetProvenanceHash(string newProvenanceHash);

    /// @notice Emitted when reveal timestamp is set.
    /// @param newRevealTime The new reveal timestamp.
    event SetRevealTime(uint256 newRevealTime);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice The per-account mint limit.
    function maxPerAccount() external view returns (uint256);

    /// @notice The state of the mint.
    function mintActive() external view returns (bool);

    /// @notice The token mint cap.
    function mintCap() external view returns (uint256);

    /// @notice The total amount of tokens minted by a given user account.
    /// @param account The user account address.
    function minted(address account) external view returns (uint256);

    /// @notice The current mint phase.
    function mintPhase() external view returns (MintPhase);

    /// @notice The offset that determines how each token ID corresponds to a token URI post-reveal.
    function offset() external view returns (uint256);

    /// @notice The provenance hash of post-reveal art.
    function provenanceHash() external view returns (string memory);

    /// @notice The total amount of reserved tokens minted.
    function reserveMinted() external view returns (uint256);

    /// @notice The timestamp from which the collection metadata can be revealed.
    function revealTime() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Burn unsold tokens.
    ///
    /// @dev Emits a {BurnUnsold} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    /// - Can only be called when token mint is paused.
    /// - `burnAmount` cannot exceed remaining mints.
    ///
    /// @param burnAmount The amount of tokens to burn.
    function burnUnsold(uint256 burnAmount) external;

    /// @notice Mint new tokens during the private phase of the mint.
    ///
    /// @dev Emits a {Mint} event.
    ///
    /// @dev Requirements:
    /// - Can only be called when token mint is active.
    /// - Can only be called when private mint phase is set.
    /// - Caller account must be allowed to mint.
    /// - `mintAmount` cannot exceed caller's per-account mint limit.
    /// - `mintAmount` cannot exceed remaining mints.
    /// - Can only be called when caller has enough MFT balance to be eligible.
    ///
    /// @param mintAmount The amount of tokens to mint.
    /// @param merkleProof The merkle proof of caller being allowed to mint.
    function mintPrivate(uint256 mintAmount, bytes32[] calldata merkleProof) external;

    /// @notice Mint new tokens during the public phase of the mint.
    ///
    /// @dev Emits a {Mint} event.
    ///
    /// @dev Requirements:
    /// - Can only be called when token mint is active.
    /// - Can only be called when public mint phase is set.
    /// - `mintAmount` cannot exceed caller's per-account mint limit.
    /// - `mintAmount` cannot exceed remaining mints.
    /// - Can only be called when caller has enough MFT balance to be eligible.
    ///
    /// @param mintAmount The amount of tokens to mint.
    function mintPublic(uint256 mintAmount) external;

    /// @notice Mint reserved tokens.
    ///
    /// @dev Emits a {Reserve} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    /// - `reserveAmount` cannot exceed remaining reserve.
    ///
    /// @param reserveAmount The amount of reserved tokens to mint.
    /// @param recipient The recipient of reserved tokens to mint.
    function reserve(uint256 reserveAmount, address recipient) external;

    /// @notice Reveal the collection metadata.
    ///
    /// @dev Emits a {Reveal} event indirectly through a transaction initiated by the VRF Coordinator.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    /// - Can only be called after `revealTime` has passed.
    /// - Can only be called once during the contract's lifetime.
    function reveal() external;

    /// @notice Set the base URI.
    ///
    /// @dev Emits a {SetBaseURI} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newBaseURI The new base URI.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Set the per-account mint limit.
    ///
    /// @dev Emits a {SetMaxPerAccount} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newMaxPerAccount The new per-account mint limit.
    function setMaxPerAccount(uint256 newMaxPerAccount) external;

    /// @notice Set the Merkle root of private phase allow list.
    ///
    /// @dev Emits a {SetMerkleRoot} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newMerkleRoot The new Merkle root.
    function setMerkleRoot(bytes32 newMerkleRoot) external;

    /// @notice Set the state of the mint.
    ///
    /// @dev Emits a {SetMintActive} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newMintActive The new mint state.
    function setMintActive(bool newMintActive) external;

    /// @notice Set the mint phase.
    ///
    /// @dev Emits a {SetMintPhase} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newMintPhase The new mint phase.
    function setMintPhase(MintPhase newMintPhase) external;

    /// @notice Set the provenance hash of post-reveal art.
    ///
    /// @dev Emits a {SetProvenanceHash} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newProvenanceHash The new provenance hash.
    function setProvenanceHash(string calldata newProvenanceHash) external;

    /// @notice Set the timestamp from which the collection metadata can be revealed.
    ///
    /// @dev Emits a {SetRevealTime} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    ///
    /// @param newRevealTime The new reveal time.
    function setRevealTime(uint256 newRevealTime) external;
}