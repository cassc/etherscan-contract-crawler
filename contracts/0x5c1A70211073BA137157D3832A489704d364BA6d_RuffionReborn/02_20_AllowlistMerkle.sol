// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./AllowlistErrors.sol";

contract AllowlistMerkle is Ownable {
    bytes32 public allowlistMerkleRoot;

    /// @notice only for accounts in allow list
    /// @dev need a proof to prove that the account is in allow list with an amount allowlisted. also needs enough allowed amount left to mint
    modifier onlyAllowlisted(bytes32[] calldata _merkleProof) {
        if (!_isAllowlisted(msg.sender, _merkleProof)) revert InvalidMerkleProof();
        _;
    }

    /// @notice constructor
    /// @param _merkleRoot the root hash of the Merkle Tree
    constructor(bytes32 _merkleRoot) {
        allowlistMerkleRoot = _merkleRoot;
    }

    /// @notice set the merkle root hash
    /// @dev If the merkle root hash is changed, the allow list has changed
    /// @param _merkleRoot the root hash of the merkle tree
    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }
    
    /// @notice Check if an account is in the allow list using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check
    /// @param _merkleProof the designated merkle proof for the leaf
    /// @return true if the account is on the allow list
    function isAllowlisted(address _account, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        return _isAllowlisted(_account, _merkleProof);
    }

    /// @notice Check if an account is in the allow list using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check
    /// @param _merkleProof the designated merkle proof for the leaf
    /// @return true if the account is on the allow list
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

}