// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemsStructure.sol";
import "./DogsFactory.sol";
import "./ItemsToUpgrade.sol";

contract CommonCasePoses is ItemsStructure {

    Item[] private _poses;

    function initCommonCasePoses() internal {
        _poses.push(Item("Common", "Common", 100));
        _poses.push(Item("Uncommon", "Uncommon", 50));
        _poses.push(Item("Rare", "Rare", 20));
        _poses.push(Item("Epic", "Epic", 5));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getCommonCasePose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract CommonCaseHairstyles is ItemsStructure {

    Item[] private _hairstyles;

    function initCommonCaseHairstyles() internal {
        _hairstyles.push(Item("Uncommon", "Uncommon", 50));
        _hairstyles.push(Item("Rare", "Rare", 20));
        _hairstyles.push(Item("Epic", "Epic", 5));
    }

    function getCommonCaseHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract CommonCaseFaces is ItemsStructure {

    Item[] private _faces;

    function initCommonCaseFaces() internal {
        _faces.push(Item("Smile", "Common", 100));
        _faces.push(Item("Surprised", "Common", 100));
        _faces.push(Item("Angry", "Uncommon", 50));
        _faces.push(Item("LMAO", "Uncommon", 50));
        _faces.push(Item("Happy", "Rare", 20));
        _faces.push(Item("Blush", "Rare", 20));
        _faces.push(Item("Pensive", "Epic", 5));
        _faces.push(Item("Amazed", "Legendary", 1));
    }

    function getCommonCaseFace(uint256 id) internal view returns (Item memory) {
        return getItem(_faces, id);
    }
}

contract CommonCaseColors is ItemsStructure {

    Item[] private _colors;

    function initCommonCaseColors() internal {
        _colors.push(Item("Fog", "Common", 100));
        _colors.push(Item("Thundercloud", "Common", 100));
        _colors.push(Item("Asphalt", "Common", 100));
        _colors.push(Item("Smog", "Uncommon", 50));
        _colors.push(Item("Coffe", "Uncommon", 50));
        _colors.push(Item("Sandstone", "Uncommon", 50));
        _colors.push(Item("Cloud Shadow", "Rare", 20));
        _colors.push(Item("Pollen", "Rare", 20));
        _colors.push(Item("Honey", "Epic", 5));
        _colors.push(Item("Red Clay", "Legendary", 1));
    }

    function getCommonCaseColor(uint256 id) internal view returns (Item memory) {
        return getItem(_colors, id);
    }
}

contract CommonCase is CommonCasePoses, CommonCaseHairstyles, CommonCaseFaces, CommonCaseColors, LegendaryPose, ItemsToUpgrade, Ownable, ReentrancyGuard {
    
    using Strings for uint256;

    DogsFactory public NFTFactory; 
    IERC20 public Token;
    
    mapping(address => uint256) public openedAFreeCase;

    uint256 public casePrice;
    address public walletForTokens;

    constructor (DogsFactory _nftFactory, IERC20 _token) {
        initCommonCasePoses();
        initCommonCaseHairstyles();
        initCommonCaseFaces();
        initCommonCaseColors();

        NFTFactory = _nftFactory;
        Token = _token;
    }

    function setWallet(address _wallet) public onlyOwner() {
        walletForTokens = _wallet;
    }

    function setPrice(uint256 _casePrice) public onlyOwner() {
        casePrice = _casePrice;
    }

    function FreeOpenCommonCase() public nonReentrant() {
        require(openedAFreeCase[msg.sender] == 0, "CommonCase: You have already opened a free case");

        openedAFreeCase[msg.sender]++;

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getCommonCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getCommonCaseColor(id);

            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getCommonCaseHairstyle(id);
            Item memory face = getCommonCaseFace(id);
            Item memory color = getCommonCaseColor(id);

            string[] memory rarity = new string[](4);
            rarity[0] = pose.Rarity;
            rarity[1] = hairstyle.Rarity;
            rarity[2] = face.Rarity;
            rarity[3] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", pose, hairstyle, face, color, balls, bones, dogFood, medals);
        }
    }

    function OpenCommonCase() public nonReentrant() {
        require(Token.balanceOf(msg.sender) >= casePrice, "CommonCase: Not enough tokens");
        
        bool check = Token.transferFrom(msg.sender, walletForTokens, casePrice);
        require(check == true, "CommonCase: Oops, some problem");

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getCommonCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getCommonCaseColor(id);
            
            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getCommonCaseHairstyle(id);
            Item memory face = getCommonCaseFace(id);
            Item memory color = getCommonCaseColor(id);

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