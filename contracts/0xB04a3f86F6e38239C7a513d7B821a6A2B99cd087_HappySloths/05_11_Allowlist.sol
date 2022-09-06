pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Allowlist is Ownable {
    bytes32 public merkleRoot;
    bool public onlyAllowlistMode = false;

    /**
        * @dev Update merkle root to reflect changes in Allowlist
        * @param _newMerkleRoot new merkle root to reflect most recent Allowlist
        */
    function updateMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        require(_newMerkleRoot != merkleRoot, "Merkle root will be unchanged!");
        merkleRoot = _newMerkleRoot;
    }

    /**
        * @dev Check the proof of an address if valid for merkle root
        * @param _to address to check for proof
        * @param _merkleProof Proof of the address to validate against root and leaf
        */
    function isAllowlisted(address _to, bytes32[] calldata _merkleProof) public view returns(bool) {
        require(merkleRoot != 0, "Merkle root is not set!");
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }


    function enableAllowlistOnlyMode() public onlyOwner {
        onlyAllowlistMode = true;
    }

    function disableAllowlistOnlyMode() public onlyOwner {
        onlyAllowlistMode = false;
    }
}