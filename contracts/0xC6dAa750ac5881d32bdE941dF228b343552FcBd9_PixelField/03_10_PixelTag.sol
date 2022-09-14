// SPDX-License-Identifier: MIT
// www.PixelRoyale.xyz
/*
 ____ ____ ____ ____ ____ ____ ____ ____ ____ 
||P |||i |||x |||e |||l |||T |||a |||g |||s ||
||__|||__|||__|||__|||__|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
 
 */

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import {Base64} from "base64-sol/base64.sol";
import {TraitAssembly} from "./TraitAssembly.sol";

contract PixelTags is ERC721A, Ownable {
    //---------- Vars ----------//
    address public contractCreator;
    address public pixelRoyale;
    uint256 public constant MAXTAGS = 4443;
    string private baseURI;
    //---------- On-Chain Gen Art ----------//
    uint16 private pixelIndex = 1;
    mapping(uint256 => uint32) private pixelTags;
    //---------- Metadata Snippets ----------//
    string private comb1 = '","description": "4443 On-Chain PixelTags given out for confirmed kills in the PixelRoyale BATTLE GAME. Collect the PixelTags for a chance to win 10% of the PixelRoyale prize pool!","external_url": "https://pixelroyale.xyz/","attributes": [{"trait_type": "Background","value": "';
    string private comb2 = '"},{"trait_type": "Base","value": "';
    string private comb3 = '"},{"trait_type": "Soul","value": "';
    string private comb4 = '"},{"trait_type": "Accessoire","value": "';
    string private comb5 = '"},{"trait_type": "Mouth","value": "';
    string private comb6 = '"},{"trait_type": "Eyes","value": "';
    string private comb7 = '"}],"image": "data:image/svg+xml;base64,';
    string private comb8 = '"}';
    //---------- Trait Names ----------//
    string[4] maTrait = ["Ag", "Au", "Pt", "Rn"];

    //---------- Construct ERC721A TOKEN ----------//
    constructor() ERC721A("PixelTags BATTLE GAME", "PTBG") {
      contractCreator = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    //---------------------------------------------------------------------------------------------
    //---------- MINT FUNCTIONS ----------//
    //---------- Set Origin Contract ----------//
    function setMintContract(address _addr) external onlyOwner {
      pixelRoyale = _addr;
    }

    //---------- Mint PixelTag ----------//
    function mintPixelTag(address _receiver) external {
        require(msg.sender == pixelRoyale, "Only Contract can mint");
        uint256 total = totalSupply();
        require(total < MAXTAGS, "The GAME has most likely concluded");
        // Mint
        _safeMint(_receiver, 1);
        pixelTags[pixelIndex] = uint32(bytes4(keccak256(abi.encodePacked(block.timestamp, pixelIndex, msg.sender))));
        pixelIndex++;
    }

    //---------------------------------------------------------------------------------------------
    //---------- METADATA GENERATION ----------//

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'There is no Token with that ID');
        //Start JSON and SVG Generation by creating file headers
        bytes memory json = abi.encodePacked('{"name": "Pixel Tag #',Strings.toString(_tokenId)); // --> JSON HEADER
        bytes memory img = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" witdh="640" height="640" viewBox="0 0 16 16">'); // --> SVG HEADER
        uint32 seed = pixelTags[_tokenId];
        //Init Trait Strings
        string memory trait1;
        string memory trait2;
        string memory svg2;
        string memory trait3;
        string memory svg3;
        string memory trait4;
        string memory svg4;
        //Init Color Strings 
        string memory basePrimeCol;
        string memory baseSecondCol;
        string memory backgroundColor = Strings.toString((seed%36)*10); 
        string memory soulColor =  Strings.toString((seed%72)*5);

        // ------ BASE COLOR TRAIT ----- //
        if(seed%99==0) { //--> 1%
            trait1 = maTrait[3];
            basePrimeCol ="179,24%,61%";
            baseSecondCol = "179,100%,86%";
        }
        else if(seed%99>=1 && seed%99<=5) { //--> 5%
            trait1 = maTrait[2];
            basePrimeCol ="180,6%,57%";
            baseSecondCol = "178,53%,88%";
        }
        else if(seed%99>=6 && seed%99<=20) { //--> 15%
            trait1 = maTrait[1];
            basePrimeCol ="46,67%,48%";
            baseSecondCol = "46,100%,70%";
        }
        else { //--> 79%
            trait1 = maTrait[0];
            basePrimeCol ="180,2%,40%";
            baseSecondCol = "180,2%,80%";
        }

        // ------ ACCESSORY TRAIT ----- //
        if(seed%99>=75) { //--> 24%
            (svg2,trait2) = ("","None");
        }
        else { //--> 76%
            (svg2,trait2) = TraitAssembly.choseA(seed);
        }

        // ------ MOUTH TRAIT ----- //
        (svg3,trait3) = TraitAssembly.choseM(seed);

        // ------ EYE TRAIT ----- //
        (svg4,trait4) = TraitAssembly.choseE(seed);

        // ----- JSON ASSEMBLY ------//
        json = abi.encodePacked(json,comb1,backgroundColor);
        json = abi.encodePacked(json,comb2,trait1);
        json = abi.encodePacked(json,comb3,soulColor);
        json = abi.encodePacked(json,comb4,trait2);
        json = abi.encodePacked(json,comb5,trait3);
        json = abi.encodePacked(json,comb6,trait4);

        // ----- SVG ASSEMBLY ------//
        //BACKGROUND//
        img = abi.encodePacked(img, '<rect x="0" y="0" width="16" height="16" fill="hsl(',backgroundColor,',100%,90%)"/>');
        //BASE// 
        img = abi.encodePacked(img, '<polygon points="5,1 5,2 4,2 4,3 3,3 3,4 3,13 4,13 4,14 5,14 5,15 11,15 11,14 12,14 12,13 13,13 13,3 12,3 12,2 11,2 11,1" fill="hsl(',basePrimeCol,')"/>');  // --> Outline
        img = abi.encodePacked(img, '<polygon points="5,2 5,3 4,3 4,3 4,3 4,4 4,13 5,13 5,14 6,14 6,14 11,14 11,13 11,13 12,13 12,3 11,3 11,2 11,2" fill="hsl(',baseSecondCol,')"/>'); //--> Inner
        //ACCESSORY
        img = abi.encodePacked(img, svg2);
        //MOUTH
        img = abi.encodePacked(img, svg3);
        //EYES
        img = abi.encodePacked(img, svg4);
        // ----- CLOSE OFF SVG AND JSON ASSEMBLY ------//
        img = abi.encodePacked(img, '</svg>');
        json = abi.encodePacked(json,comb7,Base64.encode(img),comb8);
        // ----- RETURN BASE64 ENCODED METADATA ------//
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }
}
//---------------------------------------------------------------------------------------------
//---------- LAY OUT INTERFACE ----------//
interface InterfacePixelTags {
    function mintPixelTag(address _receiver) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}