// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Capsule.sol";
import "./Wearable.sol";

contract Reveal is ReentrancyGuard, Ownable {
    Capsule private _capsule;
    Wearable private _wearable;
    mapping(uint256 => uint256) public tokenCapsule;
    mapping(uint256 => string) public tokenType;
    event revealMintEvent(
        address user,
        uint256 quantity,
        uint256[] capsuleIds,
        string name, 
        uint256 tokenId
    );

    function setCapsule(address addr) external onlyOwner {
        _capsule = Capsule(addr);
    }

    function setWearable(address addr) external onlyOwner {
        _wearable = Wearable(addr);
    }

    function getCapsuleIdFromTokenId(uint256 tokenId) public view returns (uint256) {
        return tokenCapsule[tokenId];
    }

    function getTokenTypeFromTokenId(uint256 tokenId) public view returns (string memory) {
        return tokenType[tokenId];
    }

    function reveal(uint256[] calldata capsuleIds) external nonReentrant {
        for (uint256 i = 0; i < capsuleIds.length; i++) {
            require(
                msg.sender == _capsule.ownerOf(capsuleIds[i]),
                "caller is not owner of this token"
            );
        }

        for (uint256 i = 0; i < capsuleIds.length; i++) {
            _capsule.burn(capsuleIds[i]);
        }

        _wearable.revealMint(capsuleIds.length, msg.sender, "Hat");
        uint256 firstTokenId = _wearable.totalSupply() - capsuleIds.length;
        for (uint256 i = 0; i < capsuleIds.length; i++) {
            tokenCapsule[firstTokenId + i] = capsuleIds[i];
            tokenType[firstTokenId + i] = "Hat";
        }
        emit revealMintEvent(msg.sender, 1, capsuleIds, "Hat", firstTokenId);
        
        _wearable.revealMint(capsuleIds.length, msg.sender, "Shirt");
        firstTokenId = _wearable.totalSupply() - capsuleIds.length;
        for (uint256 i = 0; i < capsuleIds.length; i++) {
            tokenCapsule[firstTokenId + i] = capsuleIds[i];
            tokenType[firstTokenId + i] = "Shirt";
        }
        emit revealMintEvent(msg.sender, 1, capsuleIds, "Shirt", firstTokenId);
    }
}