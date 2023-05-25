// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IWhitelist.sol";

/// @notice Abstract Whitelist provider contract.
/// Encapuslates merkle root validation with proofs + hash construction.
abstract contract Whitelist is IWhitelist {
    /// @dev Verify if the merkle proof is valid.
    function _isValidMerkleProof(address account, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _getWhitelistMerkleRoot(), _constructHash(account));
    }

    /// @dev Construct the hash used for merkle root validation.
    function _constructHash(address account) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), account, block.chainid));
    }

    /// @dev Return the merkle root.
    function _getWhitelistMerkleRoot() internal view virtual returns (bytes32);
}