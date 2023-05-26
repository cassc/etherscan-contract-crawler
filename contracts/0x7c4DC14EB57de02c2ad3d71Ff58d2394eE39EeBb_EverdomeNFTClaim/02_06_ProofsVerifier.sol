pragma solidity ^0.8.0;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface Mintable {
    function mint(address to, uint256 tokenId) external;
}

contract ProofsVerifier is Ownable{

    using MerkleProof for bytes32[];
    
    function getNode(uint256 nft_id, address owner) public pure returns(bytes32) {
        return keccak256(abi.encode(nft_id,owner));
    }

    function verify(bytes32 root, bytes32[] calldata proof, bytes32 leaf) public pure returns(bool){
        return proof.verify(root, leaf);
    }

}