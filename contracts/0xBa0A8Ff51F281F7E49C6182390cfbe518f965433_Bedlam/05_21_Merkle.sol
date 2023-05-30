//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Merkle {    
    bytes32 immutable private whitelist;
    bytes32 immutable private phaseOne;

    constructor(bytes32 _whitelist, bytes32 _phaseOne) {
        whitelist = _whitelist;
        phaseOne = _phaseOne;
    }

    function _whitelistLeaf(address account, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _phaseOneLeaf(address account, uint256 totalAllocated)
    internal pure returns (bytes32)
    {   
        return keccak256(abi.encodePacked(totalAllocated, account));
    }

    function _whitelistVerify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, whitelist, leaf);
    }

    function _phaseOneVerify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, phaseOne, leaf);
    }
}