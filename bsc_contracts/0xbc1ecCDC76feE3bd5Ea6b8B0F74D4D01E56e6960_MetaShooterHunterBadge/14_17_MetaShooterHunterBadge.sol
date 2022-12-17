// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./MetaShooterNFT.sol";
import "./MetaShooterNFTMinter.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract MetaShooterHunterBadge is Ownable {
    using Strings for uint256;

    address public minterAddress;
    address public nftAddress;

    mapping(address => uint32) public userAssignedBadgeLevel;
    mapping(address => uint32) public userRewardedBadgeLevel;
    mapping(uint32 => uint32) public badgeLevelToItemId;
    mapping(uint32 => string) public badgeLevelToItemURI;
    uint32[] public badgeLevels;

    constructor(address _nftAddress, address _minterAddress) {
        nftAddress = _nftAddress;
        minterAddress = _minterAddress;
    }

    function receiveBadge() public {
        require(userAssignedBadgeLevel[msg.sender] > 0, "MetaShooterBadgeCrafter: not eligible for badge");
        require(userRewardedBadgeLevel[msg.sender] > 0, "MetaShooterBadgeCrafter: badge already crafted");

        MetaShooterNFTMinter(minterAddress).mintNFT(msg.sender, badgeLevelToItemId[userAssignedBadgeLevel[msg.sender]]);
        userRewardedBadgeLevel[msg.sender] = userAssignedBadgeLevel[msg.sender];
    }

    function upgradeBadge(uint256 tokenId) public {
        require(userAssignedBadgeLevel[msg.sender] < userRewardedBadgeLevel[msg.sender], "MetaShooterBadgeCrafter: cant upgrade badge");

        string memory itemURI = MetaShooterNFT(nftAddress).tokenURI(tokenId);
        if (keccak256(abi.encodePacked((badgeLevelToItemURI[userAssignedBadgeLevel[msg.sender]]))) == keccak256(abi.encodePacked((itemURI)))){
            MetaShooterNFT(nftAddress).safeTransferFrom(msg.sender, address(0), tokenId);
            MetaShooterNFTMinter(minterAddress).mintNFT(msg.sender, badgeLevelToItemId[userAssignedBadgeLevel[msg.sender]]);
            userRewardedBadgeLevel[msg.sender] = userAssignedBadgeLevel[msg.sender];
        } else {
            revert("MetaShooterBadgeCrafter: wrong old badge level");
        }
    }

    function updateUserAssignedBadges(address[] calldata users, uint32[] calldata badgeLevels) public onlyOwner {
        require(users.length == badgeLevels.length, "MetaShooterBadgeCrafter: different parameter lengths");

        for (uint i = 0; i < users.length; i++) {
            userAssignedBadgeLevel[users[i]] = badgeLevels[i];
        }
    }

    function addBadgeLevels(uint32[] calldata itemIds, string[] calldata itemURIs) public onlyOwner {
        require(itemURIs.length == itemIds.length, "MetaShooterBadgeCrafter: different parameter lengths");

        for (uint i = 0; i < itemIds.length; i++) {
            uint32 level = uint32(badgeLevels.length) + uint32(1);
            badgeLevels.push(level);
            badgeLevelToItemId[level] = itemIds[i];
            badgeLevelToItemURI[level] = itemURIs[i];
        }
    }

    function removeBadgeLevels() public onlyOwner {
        delete badgeLevels;
    }
}