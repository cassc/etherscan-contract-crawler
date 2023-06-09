// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContextMixin} from "../common/ContextMixin.sol";
import {IMintableERC721} from "../common/IMintableERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TransportMinter is Ownable, ContextMixin {
    using MerkleProof for bytes32[];

    mapping(uint256 => bool) public isMinted;

    IMintableERC721 public netvrkTransport;

    bytes32 merkleRoot;

    event TransportMinted(address indexed minter, uint256 tokenId);

    constructor(address transportAddress) {
        netvrkTransport = IMintableERC721(transportAddress);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function redeemTransport(uint256 tokenId, bytes32[] memory proof) public {
        require(merkleRoot != 0, "TransportMinter: no MerkleRoot yet");
        require(isMinted[tokenId] == false, "TransportMinter: Already Minted");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender, tokenId))), "TransportMinter: Not Allocated");
        address minter = msg.sender;

        isMinted[tokenId] = true;

        netvrkTransport.mint(minter, tokenId);
        emit TransportMinted(minter, tokenId);
    }

    function batchRedeemTransports(uint256[] calldata tokenIds, bytes32[][] memory proofs) public 
    {
        require(merkleRoot != 0, "TransportMinter: no MerkleRoot yet");
        uint256 tokenId;        
        address minter = msg.sender;        

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];  
            require(proofs[i].verify(merkleRoot,keccak256(abi.encodePacked(minter,tokenId))),"TransportMinter: Not Allocated");   
            require(isMinted[tokenId] == false, "TransportMinter: Already Minted");            
            isMinted[tokenId] = true;
            netvrkTransport.mint(minter, tokenId);
            emit TransportMinted(minter, tokenId);
        }
    }

    function _updateAddresses(address transportAddress) external onlyOwner {
        netvrkTransport = IMintableERC721(transportAddress);
    }
}