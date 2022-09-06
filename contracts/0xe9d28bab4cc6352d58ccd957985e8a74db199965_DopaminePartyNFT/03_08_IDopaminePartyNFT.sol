// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IDopaminePartyNFTEventsAndErrors} from "../interfaces/IDopaminePartyNFTEventsAndErrors.sol";

/// @title Dopamine Party NFT Interface
interface IDopaminePartyNFT is IDopaminePartyNFTEventsAndErrors {

    /// @notice returns the URI of the specified token
    /// @param id The queried token id.
    function uri(uint256 id) external returns (string memory);

    /// @notice Sets the base URI to `newBaseURI`.
    /// @param newBaseURI The new base metadata URI to set for the collection.
    /// @dev This function is only callable by the owner address.
    function setBaseURI(string calldata newBaseURI) external;

    /// @notice Sets the final metadata URI for NFT type `id` to `uri`.
    /// @dev This function is only callable by the owner address, and reverts
    ///  if the specified NFT of type `id` does not exist.
    /// @param id The id of the NFT whose final metadata URI is being set.
    /// @param newTokenURI The finalized IPFS / Arweave metadata URI.
    function setTokenURI(uint256 id, string calldata newTokenURI) external;

    /// @notice Sets the owner address to `newOwner`.
    /// @param newOwner The address of the new owner.
    /// @dev This function is only callable by the owner address.
    function setOwner(address newOwner) external;

    /// @notice Creates for NFT type `id` an allowlist for claiming.
    /// @dev This function is only callable by the contract owner.
    /// @param id The id of the NFT being made claimable.
    /// @param allowlistRoot The merkle root of the allowlist for this NFT type.
    function allowlist(uint256 id, bytes32 allowlistRoot) external;

    /// @notice Mints NFTs of type `id` to all specified addresses `addresses`.
    /// @dev This function is only callable by the contract owner.
    /// @param id The id of the NFT type being minted.
    /// @param addresses The list of addresses receiving the minted NFT.
    function airdrop(uint256 id, address[] calldata addresses) external;

    /// @notice Mints allowlisted NFT of type `id` to the sender address if
    ///  merkle proof `proof` proves they were allowlisted for that NFT type.
    /// @dev Reverts if invalid proof is provided or claimer isn't allowlisted.
    /// The allowlist is formed using sender addresses as leaves.
    /// @param proof The Merkle proof of the claim as a bytes32 array.
    /// @param id The id of the Dopamine party NFT being claimed.
    function claim(
        bytes32[] calldata proof,
        uint256 id
    ) external;
}