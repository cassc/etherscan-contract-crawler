// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ItemsStructure.sol";
import "./DogsFactory.sol";
import "./ItemsToUpgrade.sol";

contract LegendaryCasePoses is ItemsStructure {

    Item[] private _poses;

    function initLegendaryCasePoses() internal {
        _poses.push(Item("Common", "Common", 12));
        _poses.push(Item("Uncommon", "Uncommon", 8));
        _poses.push(Item("Rare", "Rare", 5));
        _poses.push(Item("Epic", "Epic", 2));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getLegendaryCasePose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract LegendaryCaseFaces is ItemsStructure {

    Item[] private _faces;

    function initLegendaryCaseFaces() internal {
        _faces.push(Item("Smile", "Common", 12));
        _faces.push(Item("Surprised", "Common", 12));
        _faces.push(Item("Angry", "Uncommon", 8));
        _faces.push(Item("LMAO", "Uncommon", 8));
        _faces.push(Item("Happy", "Rare", 5));
        _faces.push(Item("Blush", "Rare", 5));
        _faces.push(Item("Pensive", "Epic", 2));
        _faces.push(Item("Amazed", "Legendary", 1));
    }

    function getLegendaryCaseFace(uint256 id) internal view returns (Item memory) {
        return getItem(_faces, id);
    }
}

contract LegendaryCaseHairstyles is ItemsStructure {

    Item[] private _hairstyles;

    function initLegendaryCaseHairstyles() internal {
        _hairstyles.push(Item("Uncommon", "Uncommon", 8));
        _hairstyles.push(Item("Rare", "Rare", 5));
        _hairstyles.push(Item("Epic", "Epic", 2));
    }

    function getLegendaryCaseHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract LegendaryCaseColors is ItemsStructure {

    Item[] private _colors;

    function initLegendaryCaseColors() internal {
        _colors.push(Item("Fog", "Common", 12));
        _colors.push(Item("Thundercloud", "Common", 12));
        _colors.push(Item("Asphalt", "Common", 12));
        _colors.push(Item("Smog", "Uncommon", 8));
        _colors.push(Item("Coffe", "Uncommon", 8));
        _colors.push(Item("Sandstone", "Uncommon", 8));
        _colors.push(Item("Cloud Shadow", "Rare", 5));
        _colors.push(Item("Pollen", "Rare", 5));
        _colors.push(Item("Honey", "Epic", 2));
        _colors.push(Item("Red Clay", "Legendary", 1));
    }

    function getLegendaryCaseColor(uint256 id) internal view returns (Item memory) {
        return getItem(_colors, id);
    }
}

contract LegendaryCase is LegendaryCasePoses, LegendaryCaseFaces, LegendaryCaseHairstyles, LegendaryCaseColors, LegendaryPose, ItemsToUpgrade, Ownable, ReentrancyGuard {
    
    using Strings for uint256;

    DogsFactory public NFTFactory; 
    IERC20 public Token;
    
    uint256 public casePrice;
    address public walletForTokens;

    constructor (DogsFactory _nftFactory, IERC20 _token) {
        initLegendaryCasePoses();
        initLegendaryCaseHairstyles();
        initLegendaryCaseFaces();
        initLegendaryCaseColors();

        NFTFactory = _nftFactory;
        Token = _token;
    }

    function setWallet(address _wallet) public onlyOwner() {
        walletForTokens = _wallet;
    }

    function setPrice(uint256 _casePrice) public onlyOwner() {
        casePrice = _casePrice;
    }

    function OpenLegendaryCase() public nonReentrant() {
        require(Token.balanceOf(msg.sender) >= casePrice, "EpicCase: Not enough tokens");
        
        bool check = Token.transferFrom(msg.sender, walletForTokens, casePrice);
        require(check == true, "EpicCase: Oops, some problem");

        uint256 id = NFTFactory.getId();

        string memory name = string.concat("Dog ", id.toString());

        Item memory pose = getLegendaryCasePose(id);

        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(id);
            Item memory color = getLegendaryCaseColor(id);

            string[] memory rarity = new string[](2);
            rarity[0] = legendaryPose.Rarity;
            rarity[1] = color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, "Child");

            NFTFactory.createDog(msg.sender, name, "Child", legendaryPose, Item("","",0), Item("","",0), color, balls, bones, dogFood, medals);
        } else {
            Item memory hairstyle = getLegendaryCaseHairstyle(id);
            Item memory face = getLegendaryCaseFace(id);
            Item memory color = getLegendaryCaseColor(id);

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