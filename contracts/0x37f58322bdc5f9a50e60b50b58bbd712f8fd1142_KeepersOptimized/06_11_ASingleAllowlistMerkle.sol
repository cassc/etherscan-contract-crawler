// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./WhitelistErrors.sol";

/// @title Merkle Proof based whitelist Base Abstract Contract
/// @author karmabadger
/// @notice Uses an address and an amount
/// @dev inherit this contract to use the whitelist functionality
abstract contract ASingleAllowlistMerkle is Ownable {
    bytes32 public allowlistMerkleRoot; // root of the merkle tree

    /// @notice constructor
    /// @param _merkleRoot the root of the merkle tree
    constructor(bytes32 _merkleRoot) {
        allowlistMerkleRoot = _merkleRoot;
    }

    /// @notice only for whitelisted accounts
    /// @dev need a proof to prove that the account is whitelisted with an amount whitelisted. also needs enough allowed amount left to mint
    modifier onlyAllowlisted(bytes32[] calldata _merkleProof) {
        if (!_isAllowlisted(msg.sender, _merkleProof)) revert InvalidMerkleProof();
        _;
    }

    /* whitelist admin functions */
    /// @notice set the merkle root
    /// @dev If the merkle root is changed, the whitelist is reset
    /// @param _merkleRoot the root of the merkle tree
    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    /* whitelist user functions */
    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function _isAllowlisted(address _account, bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_account))
            );
    }

    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function isAllowlisted(address _account, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        return _isAllowlisted(_account, _merkleProof);
    }
}