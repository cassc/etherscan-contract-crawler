// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemsStructure.sol";
import "./DogsFactory.sol";
import "./ItemsToUpgrade.sol";

contract RareCasePoses is ItemsStructure {

    Item[] private _poses;

    function initRareCasePoses() internal {
        _poses.push(Item("Common", "Common", 63));
        _poses.push(Item("Uncommon", "Uncommon", 33));
        _poses.push(Item("Rare", "Rare", 14));
        _poses.push(Item("Epic", "Epic", 4));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getRareCasePose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract RareCaseFaces is ItemsStructure {

    Item[] private _faces;

    function initRareCaseFaces() internal {
        _faces.push(Item("Smile", "Common", 63));
        _faces.push(Item("Surprised", "Common", 63));
        _faces.push(Item("Angry", "Uncommon", 33));
        _faces.push(Item("LMAO", "Uncommon", 33));
        _faces.push(Item("Happy", "Rare", 14));
        _faces.push(Item("Blush", "Rare", 14));
        _faces.push(Item("Pensive", "Epic", 4));
        _faces.push(Item("Amazed", "Legendary", 1));
    }

    function getRareCaseFace(uint256 id) internal view returns (Item memory) {
        return getItem(_faces, id);
    }
}

contract RareCaseHairstyles is ItemsStructure {

    Item[] private _hairstyles;

    function initRareCaseHairstyles() internal {
        _hairstyles.push(Item("Uncommon", "Uncommon", 33));
        _hairstyles.push(Item("Rare", "Rare", 14));
        _hairstyles.push(Item("Epic", "Epic", 4));
    }

    function getRareCaseHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract RareCaseColors is ItemsStructure {

    Item[] private _colors;

    function initRareCaseColors() internal {
        _colors.push(Item("Fog", "Common", 63));
        _colors.push(Item("Thundercloud", "Common", 63));
        _colors.push(Item("Asphalt", "Common", 63));
        _colors.push(Item("Smog", "Uncommon", 33));
        _colors.push(Item("Coffe", "Uncommon", 33));
        _colors.push(Item("Sandstone", "Uncommon", 33));
        _colors.push(Item("Cloud Shadow", "Rare", 14));
        _colors.push(Item("Pollen", "Rare", 14));
        _colors.push(Item("Honey", "Epic", 4));
        _colors.push(Item("Red Clay", "Legendary", 1));
    }

    function getRareCaseColor(uint256 id) internal view returns (Item memory) {
        return getItem(_colors, id);
    }
}

contract RareCase is RareCasePoses, RareCaseHairstyles, RareCaseFaces, RareCaseColors, LegendaryPose, ItemsToUpgrade, Ownable, ReentrancyGuard {

    using Strings for uint256;

    DogsFactory public NFTFactory; 
    IERC20 public Token;
    
    uint256 public casePrice;
    address public walletForTokens;

    constructor (DogsFactory _nftFactory, IERC20 _token) {
        initRareCasePoses();
        initRareCaseHairstyles();
        initRareCaseFaces();
        initRareCaseColors();

        NFTFactory = _nftFactory;
        Token = _token;
    }

    function setWallet(address _wallet) public onlyOwner() {
        walletForTokens = _wallet;
    }

    function setPrice(uint256 _casePrice) public onlyOwner() {
        casePrice = _casePrice;
    }

    function OpenRareCase() public nonReentrant() {
        require(Token.balanceOf(msg.sender) >= casePrice, "RareCase: Not enough tokens");
        
        bool check = Token.transferFrom(msg.sender, walletForTokens, casePrice);
        require(check == true, "RareCase: Oops, some problem");

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getRareCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getRareCaseColor(id);
            
            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getRareCaseHairstyle(id);
            Item memory face = getRareCaseFace(id);
            Item memory color = getRareCaseColor(id);

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