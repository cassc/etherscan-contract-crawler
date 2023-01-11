// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract WhitelistMerkle is Ownable {
    bytes32 public premiumWhitelistMerkleRoot;
    bytes32 public standardWhitelistMerkleRoot;

    /* @notice constructor
       @param _premiumWhitelistMerkleRoot the root of the premium whitelist merkle tree
       @param _standardWhitelistMerkleRoot the root of the standard whitelist merkle tree
       */
    constructor(bytes32 _premiumWhitelistMerkleRoot, bytes32 _standardWhitelistMerkleRoot) {
        premiumWhitelistMerkleRoot = _premiumWhitelistMerkleRoot;
        standardWhitelistMerkleRoot = _standardWhitelistMerkleRoot;
    }

    /* @notice set the premium whitelist merkle root
       @dev If the merkle root is changed, the whitelist is reset
       @param _merkleRoot the root of the merkle tree
       */
    function setPremiumWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        premiumWhitelistMerkleRoot = _merkleRoot;
    }

    /* @notice set the standard whitelist merkle root
       @dev If the merkle root is changed, the whitelist is reset
       @param _merkleRoot the root of the merkle tree
       */
    function setStandardWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        standardWhitelistMerkleRoot = _merkleRoot;
    }

    /* @notice Check if an account is premium whitelisted
       @dev verifies the merkle proof
       @param _account the account to check if it is whitelisted
       @param _merkleProof the merkle proof of for the whitelist
       @return true if the account is whitelisted
       */
    function _isPremiumWhitelisted(address _account, bytes32[] calldata _merkleProof)
    internal
    view
    returns (bool)
    {
        return
        MerkleProof.verify(
            _merkleProof,
            premiumWhitelistMerkleRoot,
            keccak256(abi.encodePacked(_account))
        );
    }

    /* @notice Check if an account is standard whitelisted
       @dev verifies the merkle proof
       @param _account the account to check if it is whitelisted
       @param _merkleProof the merkle proof of for the whitelist
       @return true if the account is whitelisted
       */
    function _isStandardWhitelisted(address _account, bytes32[] calldata _merkleProof)
    internal
    view
    returns (bool)
    {
        return
        MerkleProof.verify(
            _merkleProof,
            standardWhitelistMerkleRoot,
            keccak256(abi.encodePacked(_account))
        );
    }

    /* @notice Check if an account is premium whitelisted
       @dev verifies the merkle proof
       @param _account the account to check if it is whitelisted
       @param _merkleProof the merkle proof of for the whitelist
       @return true if the account is whitelisted
       */
    function isPremiumWhitelisted(address _account, bytes32[] calldata _merkleProof)
    external
    view
    returns (bool)
    {
        return _isPremiumWhitelisted(_account, _merkleProof);
    }

    /* @notice Check if an account is standard whitelisted
       @dev verifies the merkle proof
       @param _account the account to check if it is whitelisted
       @param _merkleProof the merkle proof of for the whitelist
       @return true if the account is whitelisted
       */
    function isStandardWhitelisted(address _account, bytes32[] calldata _merkleProof)
    external
    view
    returns (bool)
    {
        return _isStandardWhitelisted(_account, _merkleProof);
    }
}