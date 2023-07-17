// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContextMixin} from "../common/ContextMixin.sol";
import {IMintableERC721} from "../common/IMintableERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BonusPackMinter is Ownable, ContextMixin {
    using MerkleProof for bytes32[];

    mapping(uint256 => bool) public isMinted;

    IMintableERC721 public netvrkBonusPack;

    bytes32 merkleRoot;

    event BonusPackMinted(
        address indexed minter,
        uint256 tokenId
    );

    constructor(address bonusPackAddress) {
        netvrkBonusPack = IMintableERC721(bonusPackAddress);
    }

    function setMerkleRoot(bytes32 root) onlyOwner external {
        merkleRoot = root;
    }

    function redeemBonusPack(uint256 tokenId, bytes32[] memory proof) public {
        require(merkleRoot != 0, "BonusPackMinter: no MerkleRoot yet");
        require(isMinted[tokenId] == false, "BonusPackMinter: Already Minted");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender,tokenId))), "BonusPackMinter: Not Allocated");

        address minter = msg.sender;

        isMinted[tokenId] = true;

        netvrkBonusPack.mint(minter, tokenId);
        emit BonusPackMinted(minter, tokenId);
    }

    function batchRedeemBonusPacks(uint256[] calldata tokenIds, bytes32[][] memory proofs) public 
    {
        require(merkleRoot != 0, "BonusPackMinter: no MerkleRoot yet");
        uint256 tokenId;        
        address minter = msg.sender;        

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];            
            require(proofs[i].verify(merkleRoot, keccak256(abi.encodePacked(minter,tokenId))), "BonusPackMinter: Not Allocated");
            require(isMinted[tokenId] == false, "BonusPackMinter: Already Minted");
            isMinted[tokenId] = true;
            netvrkBonusPack.mint(minter, tokenId);
            emit BonusPackMinted(minter, tokenId);
        }
    }

    function _updateAddresses(address bonusPackAddress)
        external
        onlyOwner
    {
        netvrkBonusPack = IMintableERC721(bonusPackAddress);
    }
}