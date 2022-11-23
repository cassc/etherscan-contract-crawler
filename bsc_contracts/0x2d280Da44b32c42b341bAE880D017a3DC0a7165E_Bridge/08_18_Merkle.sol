// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ZeroCopySource.sol";

library Merkle {
    /* @notice          Do hash leaf as the multi-chain does
     *  @param _data     Data in bytes format
     *  @return          Hashed value in bytes32 format
     */
    function hashLeaf(bytes memory _data) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(uint8(0x0), _data));
    }

    /* @notice          Do hash children as the multi-chain does
     *  @param _l        Left node
     *  @param _r        Right node
     *  @return          Hashed value in bytes32 format
     */
    function hashChildren(bytes32 _l, bytes32 _r) internal pure returns (bytes32 result) {
        result = sha256(abi.encodePacked(bytes1(0x01), _l, _r));
    }

    /* @notice                  Verify merkle proove
     *  @param _auditPath        Merkle path
     *  @param _root             Merkle tree root
     *  @return                  The verified value included in _auditPath
     */
    function prove(bytes memory _auditPath, bytes32 _root) internal pure returns (bytes memory) {
        uint256 off = 0;
        bytes memory value;
        (value, off) = ZeroCopySource.NextVarBytes(_auditPath, off);

        bytes32 hash = hashLeaf(value);
        uint256 size = (_auditPath.length - off) / 33;
        bytes32 nodeHash;
        uint8 pos;
        for (uint256 i = 0; i < size; i++) {
            (pos, off) = ZeroCopySource.NextUint8(_auditPath, off);
            (nodeHash, off) = ZeroCopySource.NextHash(_auditPath, off);
            if (pos == 0x00) {
                hash = hashChildren(nodeHash, hash);
            } else if (pos == 0x01) {
                hash = hashChildren(hash, nodeHash);
            } else {
                revert("merkleProve eod");
            }
        }
        require(hash == _root, "merkleProve root");
        return value;
    }
}