//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author Andrew Parker
/// @title GBA Whitelist NFT Contract
/// @notice Implementation of OpenZeppelin MerkleProof contract for GBA MiniStayPuft and Traps NFTs
contract GBAWhitelist{
    bytes32 merkleRoot;

    /// Constructor
    /// @param _merkleRoot root of merkle tree
    constructor(bytes32 _merkleRoot){
        merkleRoot = _merkleRoot;
    }

    /// Is Whitelisted
    /// @notice Is a given address whitelisted based on proof provided
    /// @param proof Merkle proof
    /// @param claimer address to check
    /// @return Is whitelisted
    function isWhitelisted(bytes32[] memory proof, address claimer) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof,merkleRoot,leaf);
    }
}