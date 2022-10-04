// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AccessControlPermissible.sol";
import "./interfaces/IWhitelistMerkleTree.sol";

contract WhitelistMerkleTree is AccessControlPermissible, IWhitelistMerkleTree {
    uint256 public merkleRootIndex;

    mapping(bytes32 => uint256) public merkleRoots;
    mapping(uint256 => bytes32) public merkleRootsById;

    function addMerkleRoot(bytes32 _merkleRoot) external onlyRole(WL_OPERATOR_ROLE) {
        merkleRootIndex++;
        merkleRoots[_merkleRoot] = merkleRootIndex;
        merkleRootsById[merkleRootIndex] = _merkleRoot;
    }

    function updateMerkleRoot(
        bytes32 _oldMerkleRoot,
        bytes32 _newMerkleRoot
    ) external onlyRole(WL_OPERATOR_ROLE) {
        require(merkleRoots[_oldMerkleRoot] != 0, "Root not exist");

        uint256 id = merkleRoots[_oldMerkleRoot];
        delete merkleRoots[_oldMerkleRoot];
        merkleRoots[_newMerkleRoot] = id;
        merkleRootsById[id] = _newMerkleRoot;
    }

    function unsetMerkleRoot(bytes32 _merkleRoot) external onlyRole(WL_OPERATOR_ROLE) {
        uint256 id = merkleRoots[_merkleRoot];
        delete merkleRoots[_merkleRoot];
        delete merkleRootsById[id];
    }

    function isRootExists(bytes32 _merkleRoot) public view returns (bool status) {
        status = merkleRoots[_merkleRoot] != 0;
    }

    /**
     * @dev See {MerkleProof-verify}.
     */
    function isWhitelisted(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    )
        external
        pure
        override
        returns (bool)
    {
        return MerkleProof.verifyCalldata(
            proof,
            root,
            leaf
        );
    }

    /**
     * @dev Returns leaf by user `_account`.
     */
    function getLeaf(address _account) external pure override returns (bytes32 leaf) {
        leaf = keccak256(abi.encodePacked(_account));
    }
}