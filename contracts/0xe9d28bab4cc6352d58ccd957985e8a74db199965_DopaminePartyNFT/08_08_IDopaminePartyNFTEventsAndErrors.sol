// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Party NFT Events & Errors Interface
interface IDopaminePartyNFTEventsAndErrors {

    /// @notice Emits when the Dopamine tab base URI is set to `baseURI`.
    /// @param baseURI The base URI of the Dopamine tab contract, as a string.
    event BaseURISet(string baseURI);

    /// @notice Emits when NFT type of id `id` has its URI set to `tokenURI`.
    /// @param id  The id of the type of NFT whose URI was set.
    /// @param tokenURI The metadata URI of the token, as a string.
    event TokenURISet(uint256 id, string tokenURI);

    /// @notice Emits when owner is changed from `oldOwner` to `newOwner`.
    /// @param oldOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emits when a new party NFT type is created.
    /// @param id The id of the new party NFT type.
    /// @param allowlistRoot The merkle root, if any, for minting to claimants.
    event PartyNFTCreated(
        uint256 indexed id,
        bytes32 allowlistRoot
    );

    /// @notice Emits when an existing party NFT type is updated.
    /// @param id The id of the party NFT type.
    /// @param allowlistRoot The updated merkle root, if any, of the allowlist.
    event PartyNFTUpdated(
        uint256 indexed id,
        bytes32 allowlistRoot
    );

    /// @notice Claim drop identifier is invalid.
    error ClaimInvalid();

    /// @notice Function callable only by the owner.
    error OwnerOnly();

    /// @notice Proof for claim is invalid.
    error ProofInvalid();

    /// @notice NFT of the specified type does not exist.
    error TokenNonExistent();

    /// @notice NFTs of the specified type may not be minted or modified.
    error TokenImmutable();

}