// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContextMixin} from "../common/ContextMixin.sol";
import {IMintableERC721} from "../common/IMintableERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ParcelMinter is Ownable, ContextMixin {
    using MerkleProof for bytes32[];

    mapping(uint256 => bool) public isMinted;

    IMintableERC721 public netvrkMap;

    bytes32 merkleRoot;

    event ParcelMinted(
        address indexed minter,
        uint256 tokenId
    );

    constructor(address mapAddress) {
        netvrkMap = IMintableERC721(mapAddress);
    }

    function setMerkleRoot(bytes32 root) onlyOwner external {
        merkleRoot = root;
    }

    function redeemParcels(uint256 tokenId, bytes32[] memory proof) public {
        require(merkleRoot != 0, "ParcelMinter: no MerkleRoot yet");
        require(isMinted[tokenId] == false, "ParcelMinter: Already Minted");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender, tokenId))), "ParcelMinter: Not Allocated");

        address minter = msg.sender;

        isMinted[tokenId] = true;

        netvrkMap.mint(minter, tokenId);
        emit ParcelMinted(minter, tokenId);
    }

    function batchRedeemParcels(uint256[] calldata tokenIds, bytes32[][] memory proofs) public {
        require(merkleRoot != 0, "ParcelMinter: no MerkleRoot yet");
        uint256 tokenId;        
        address minter = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(proofs[i].verify(merkleRoot, keccak256(abi.encodePacked(minter,tokenId))), "ParcelMinter: Not Allocated");
            require(isMinted[tokenId] == false, "ParcelMinter: Already Minted");
            isMinted[tokenId] = true;

            netvrkMap.mint(minter, tokenId);
            emit ParcelMinted(minter, tokenId);
        }
    }

    function _updateAddresses(address mapAddress)
        external
        onlyOwner
    {
        netvrkMap = IMintableERC721(mapAddress);
    }
}