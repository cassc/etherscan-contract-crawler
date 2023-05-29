// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./WhitelistErrors.sol";

/// @title Merkle Proof based whitelist Base Abstract Contract
/// @author karmabadger
/// @notice Uses an address and an amount
/// @dev inherit this contract to use the whitelist functionality
abstract contract AMultiFounderslistMerkle is Ownable {
    bytes32 public founderslistMerkleRoot; // root of the merkle tree

    // mapping(address => uint32) public whitelistMintMintedAmounts; // Whitelist minted amounts for each account.

    /// @notice constructor
    /// @param _merkleRoot the root of the merkle tree
    constructor(bytes32 _merkleRoot) {
        founderslistMerkleRoot = _merkleRoot;
    }

    /// @notice only for whitelisted accounts
    /// @dev need a proof to prove that the account is whitelisted with an amount whitelisted. also needs enough allowed amount left to mint
    modifier onlyFounderslisted(bytes32[] calldata _merkleProof, uint16 _entitlementAmount) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _entitlementAmount));
        if (!MerkleProof.verify(_merkleProof, founderslistMerkleRoot, leaf))
            revert InvalidMerkleProof();
        _;
    }

    /* whitelist admin functions */
    /// @notice set the merkle root
    /// @dev If the merkle root is changed, the whitelist is reset
    /// @param _merkleRoot the root of the merkle tree
    function setFounderslistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        founderslistMerkleRoot = _merkleRoot;
    }

    /* whitelist user functions */

    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _entitlementAmount the amount of the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function isFounderslisted(
        address _account,
        uint16 _entitlementAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account, _entitlementAmount));
        return MerkleProof.verify(_merkleProof, founderslistMerkleRoot, leaf);
    }
}