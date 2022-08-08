// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./GLPGenerator.sol";


contract GLP is ERC721A, Ownable {
  
  uint256 maxSupply;
  string secretSeed;

    constructor() ERC721A("GridsLayersPalettes", "GLP") {}

    function setContractParams(string memory _secretSeed, uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
        secretSeed = _secretSeed;
    }
    
    function mint(address recipient, uint256 quantity) external payable{
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
        require(recipient == owner(), "Only owner can mint the tokens");
        _safeMint(recipient, quantity);
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint8 layers= getLayerCount(tokenId);
        (string memory prefixTag, string memory backgroundColor) = getPrefixTag(tokenId);
        (string memory paletteSvg, uint256 opacity, string memory pattern) = GLPGenerator.getArt(tokenId, secretSeed, layers, prefixTag);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{', getProperties(layers, opacity, backgroundColor, pattern, tokenId), '"name": "GLP #', Strings.toString(tokenId + 1), '", "description": "Grids, Layers and Patterns", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(paletteSvg)), '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getLayerCount(uint256 tokenId) internal pure returns(uint8 layerCount){
       
          uint256 layerIndicator= tokenId % 7;
          if (layerIndicator == 0) {
            return 30;
          }
         else if (layerIndicator == 1) {
            return 55;
        }
        else if (layerIndicator == 2) {
            return 35;
        }
        else if (layerIndicator == 3) {
            return 45;
        }
        else if (layerIndicator == 4) {
            return 40;
        }
        else if (layerIndicator == 5) {
            return 50;
        }
        else if (layerIndicator == 6) {
            return 25;
        }
    }

    function getTempo(uint256 tokenId) internal pure returns(string memory tempo){  
          uint256 tempoIndicator= tokenId % 3;
          if (tempoIndicator == 0) {
            return 'Medium';
          }
         else if (tempoIndicator == 1) {
            return 'Fast';
          }
         else {
            return 'Slow';
         }
    }

    function getPrefixTag(uint256 tokenId) public pure returns (string memory, string memory backgroundColor) {
        string[5] memory prefixTag;
        string memory bgCode = GLPGenerator.getUniqueCode(tokenId, 2318, 'background');
         prefixTag[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"> <rect width="100%" height="100%" fill="#';
         prefixTag[1]= GLPGenerator.getHexColorCode(bgCode, 10, 16);
         prefixTag[2]= '" rx="2"/>';
        return (string(abi.encodePacked(prefixTag[0], prefixTag[1], prefixTag[2])), prefixTag[1]);
    }

    function getSecretProperty(uint256 tokenId) internal pure returns(string memory code){  
        if (tokenId < 200) {
            return 'Code#1';
          }
         else if (tokenId < 400) {
            return 'Code#2';
          }
         else if (tokenId < 600) {
            return 'Code#3';
          }
         else if (tokenId < 800) {
            return 'Code#4';
          }
        else if (tokenId < 1000) {
            return 'Code#5';
          }
         else {
            return 'Code#6';
         } 
    }

    function getProperties(uint8 layers, uint256 opacity, string memory bgColor, string memory pattern, uint256 tokenId) internal pure returns (string memory) {
         return string(abi.encodePacked('"attributes" : [{"trait_type" : "Layers","value" : "', Strings.toString(layers),'"}, {"trait_type" : "Palette","value" : "', Strings.toString(layers),' Colors"}, {"trait_type" : "Opacity","value" : "', Strings.toString(opacity),'"}, {"trait_type" : "Background","value" : "#', bgColor,'"}, {"trait_type" : "Pattern","value" : "', pattern ,'"}, {"trait_type" : "Tempo","value" : "', getTempo(tokenId) ,'"}, {"trait_type" : "Secret Type ","value" : "', getSecretProperty(tokenId) ,'"}],'));
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}