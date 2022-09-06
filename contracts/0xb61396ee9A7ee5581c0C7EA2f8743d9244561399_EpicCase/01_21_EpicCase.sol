// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemsStructure.sol";
import "./DogsFactory.sol";
import "./ItemsToUpgrade.sol";

contract EpicCasePoses is ItemsStructure {

    Item[] private _poses;

    function initEpicCasePoses() internal {
        _poses.push(Item("Common", "Common", 31));
        _poses.push(Item("Uncommon", "Uncommon", 18));
        _poses.push(Item("Rare", "Rare", 9));
        _poses.push(Item("Epic", "Epic", 3));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getEpicCasePose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract EpicCaseFaces is ItemsStructure {

    Item[] private _faces;

    function initEpicCaseFaces() internal {
        _faces.push(Item("Smile", "Common", 31));
        _faces.push(Item("Surprised", "Common", 31));
        _faces.push(Item("Angry", "Uncommon", 18));
        _faces.push(Item("LMAO", "Uncommon", 18));
        _faces.push(Item("Happy", "Rare", 9));
        _faces.push(Item("Blush", "Rare", 9));
        _faces.push(Item("Pensive", "Epic", 3));
        _faces.push(Item("Amazed", "Legendary", 1));
    }

    function getEpicCaseFace(uint256 id) internal view returns (Item memory) {
        return getItem(_faces, id);
    }
}

contract EpicCaseHairstyles is ItemsStructure {

    Item[] private _hairstyles;

    function initEpicCaseHairstyles() internal {
        _hairstyles.push(Item("Uncommon", "Uncommon", 18));
        _hairstyles.push(Item("Rare", "Rare", 9));
        _hairstyles.push(Item("Epic", "Epic", 3));
    }

    function getEpicCaseHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract EpicCaseColors is ItemsStructure {

    Item[] private _colors;

    function initEpicCaseColors() internal {
        _colors.push(Item("Fog", "Common", 31));
        _colors.push(Item("Thundercloud", "Common", 31));
        _colors.push(Item("Asphalt", "Common", 31));
        _colors.push(Item("Smog", "Uncommon", 18));
        _colors.push(Item("Coffe", "Uncommon", 18));
        _colors.push(Item("Sandstone", "Uncommon", 18));
        _colors.push(Item("Cloud Shadow", "Rare", 9));
        _colors.push(Item("Pollen", "Rare", 9));
        _colors.push(Item("Honey", "Epic", 3));
        _colors.push(Item("Red Clay", "Legendary", 1));
    }

    function getEpicCaseColor(uint256 id) internal view returns (Item memory) {
        return getItem(_colors, id);
    }
}

contract EpicCase is EpicCasePoses, EpicCaseHairstyles, EpicCaseFaces, EpicCaseColors, LegendaryPose, ItemsToUpgrade, Ownable, ReentrancyGuard {

    using Strings for uint256;

    DogsFactory public NFTFactory; 
    IERC20 public Token;
    
    uint256 public casePrice;
    address public walletForTokens;

    constructor (DogsFactory _nftFactory, IERC20 _token) {
        initEpicCasePoses();
        initEpicCaseHairstyles();
        initEpicCaseFaces();
        initEpicCaseColors();

        NFTFactory = _nftFactory;
        Token = _token;
    }

    function setWallet(address _wallet) public onlyOwner() {
        walletForTokens = _wallet;
    }

    function setPrice(uint256 _casePrice) public onlyOwner() {
        casePrice = _casePrice;
    }

    function OpenEpicCase() public nonReentrant() {
        require(Token.balanceOf(msg.sender) >= casePrice, "EpicCase: Not enough tokens");
        
        bool check = Token.transferFrom(msg.sender, walletForTokens, casePrice);
        require(check == true, "EpicCase: Oops, some problem");

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getEpicCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getEpicCaseColor(id);
            
            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getEpicCaseHairstyle(id);
            Item memory face = getEpicCaseFace(id);
            Item memory color = getEpicCaseColor(id);

            string[] memory rarity = new string[](4);
            rarity[0] = pose.Rarity;
            rarity[1] = hairstyle.Rarity;
            rarity[2] = face.Rarity;
            rarity[3] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", pose, hairstyle, face, color, balls, bones, dogFood, medals);
        }
    }
}