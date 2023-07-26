// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    Tokapi Ethereum V1
    TOKv1 / 2022 / v1.0
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//  __/\\\\\\\\\\\\\\\_______/\\\\\_______/\\\________/\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_        
//   _\///////\\\/////______/\\\///\\\____\/\\\_____/\\\//____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///__       
//    _______\/\\\_________/\\\/__\///\\\__\/\\\__/\\\//______/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_____      
//     _______\/\\\________/\\\______\//\\\_\/\\\\\\//\\\_____\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\_____     
//      _______\/\\\_______\/\\\_______\/\\\_\/\\\//_\//\\\____\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____    
//       _______\/\\\_______\//\\\______/\\\__\/\\\____\//\\\___\/\\\/////////\\\_\/\\\_________________\/\\\_____   
//        _______\/\\\________\///\\\__/\\\____\/\\\_____\//\\\__\/\\\_______\/\\\_\/\\\_________________\/\\\_____  
//         _______\/\\\__________\///\\\\\/_____\/\\\______\//\\\_\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\_ 
//          _______\///_____________\/////_______\///________\///__\///________\///__\///______________\///////////__

/// @custom:security-contact thedevs
contract TokapiEthereumV1 is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("TokapiEthereumV1", "TOKv1") {}

    string private _baseTokenURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }
}