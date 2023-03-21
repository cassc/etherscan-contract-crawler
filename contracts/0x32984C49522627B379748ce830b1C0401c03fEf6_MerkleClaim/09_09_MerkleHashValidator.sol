pragma solidity ^0.8.9;

library MerkleHashValidator {

    function validateEntry(bytes32 merkleRoot, bytes32[] calldata proof, bytes32 leaf) internal pure returns (bool) {
        
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            if(computedHash < proof[i]){
                computedHash = _computeHash(computedHash, proof[i]);
            }
            else {
                computedHash = _computeHash(proof[i], computedHash);
            }
        }
        return computedHash == merkleRoot;
    }

    function _computeHash(bytes32 left, bytes32 right) private pure returns (bytes32 value){
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            value := keccak256(0x00, 0x40)
        }
    }
}