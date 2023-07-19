// SPDX-License-Identifier: MIT
/*
                            
        C C C C C           
      C C C C C C C C C     
      A A A Z Z A Z         
    A Z A Z Z Z A Z Z Z     
    A Z A A Z Z Z A Z Z A   
    A A Z Z Z Z A A A A     
        Z Z Z Z Z Z Z       
      C C O C C O C         
    C C C O C C O C C C     
  C C C C O O O O C C C C   
  V V C O Q O O Q O C V V   
  V V V O O O O O O V V V   
  V V O O O O O O O O V V   
      O O O     O O O       
    M M M         M M M     
  M M M M         M M M M   

He wears a long-sleeved red shirt, a pair of blue overalls with yellow buttons,
 brown shoes, white gloves, and a red cap with a red "M" printed on a white circle. 
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PixelSuperMario is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    uint256 public constant BASE_PRICE = 0.01 ether;

    constructor() ERC721("PixelSuperMario", "MARIO") {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getBackground(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BACKGROUND");
    }
    
    function getCap(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CAP");
    }
    
    function getHair(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HAIR");
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD");
    }
    
    function getShirt(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SHIRT");
    }

    function getButtons(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BUTTONS");
    }

    function getGloves(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GLOVES");
    }

    function getShoes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SHOES");
    }

    function pluck(uint256 tokenId, string memory keyPrefix) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId), ownerOf(tokenId))));
        bytes memory buffer = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            buffer[i * 2 + 1] = _HEX_SYMBOLS[rand & 0xf];
            rand >>= 4;
            buffer[i * 2] = _HEX_SYMBOLS[rand & 0xf];
            rand >>= 4;
        }
        return string(buffer);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 14 16"><path fill="#',
            getBackground(tokenId),
            '" d="M0 0h1v1H0zM1 0h1v1H1zM2 0h1v1H2zM3 0h1v1H3zM4 0h1v1H4zM5 0h1v1H5zM6 0h1v1H6zM7 0h1v1H7zM8 0h1v1H8zM9 0h1v1H9zM10 0h1v1h-1zM11 0h1v1h-1zM12 0h1v1h-1zM13 0h1v1h-1zM0 1h1v1H0zM1 1h1v1H1zM2 1h1v1H2zM3 1h1v1H3zM9 1h1v1H9zM10 1h1v1h-1zM11 1h1v1h-1zM12 1h1v1h-1zM13 1h1v1h-1zM0 2h1v1H0zM1 2h1v1H1zM2 2h1v1H2zM12 2h1v1h-1zM13 2h1v1h-1zM0 3h1v1H0zM1 3h1v1H1zM2 3h1v1H2zM10 3h1v1h-1zM11 3h1v1h-1zM12 3h1v1h-1zM13 3h1v1h-1zM0 4h1v1H0zM1 4h1v1H1zM12 4h1v1h-1zM13 4h1v1h-1zM0 5h1v1H0zM1 5h1v1H1zM13 5h1v1h-1zM0 6h1v1H0zM1 6h1v1H1zM12 6h1v1h-1zM13 6h1v1h-1zM0 7h1v1H0zM1 7h1v1H1zM2 7h1v1H2zM3 7h1v1H3zM11 7h1v1h-1zM12 7h1v1h-1zM13 7h1v1h-1zM0 8h1v1H0zM1 8h1v1H1zM2 8h1v1H2zM10 8h1v1h-1zM11 8h1v1h-1zM12 8h1v1h-1zM13 8h1v1h-1zM0 9h1v1H0zM1 9h1v1H1zM12 9h1v1h-1zM13 9h1v1h-1zM0 10h1v1H0zM13 10h1v1h-1zM0 11h1v1H0zM13 11h1v1h-1zM0 12h1v1H0zM13 12h1v1h-1zM0 13h1v1H0zM13 13h1v1h-1zM0 14h1v1H0zM1 14h1v1H1zM2 14h1v1H2zM6 14h1v1H6zM7 14h1v1H7zM11 14h1v1h-1zM12 14h1v1h-1zM13 14h1v1h-1zM0 15h1v1H0zM1 15h1v1H1zM5 15h1v1H5zM6 15h1v1H6zM7 15h1v1H7zM8 15h1v1H8zM12 15h1v1h-1zM13 15h1v1h-1z"/><path fill="#',
            getCap(tokenId),
            '" d="M4 1h1v1H4zM5 1h1v1H5zM6 1h1v1H6zM7 1h1v1H7zM8 1h1v1H8zM3 2h1v1H3zM4 2h1v1H4zM5 2h1v1H5zM6 2h1v1H6zM7 2h1v1H7zM8 2h1v1H8zM9 2h1v1H9zM10 2h1v1h-1zM11 2h1v1h-1zM3 8h1v1H3zM4 8h1v1H4zM6 8h1v1H6zM7 8h1v1H7zM9 8h1v1H9zM2 9h1v1H2zM3 9h1v1H3zM4 9h1v1H4zM6 9h1v1H6zM7 9h1v1H7zM9 9h1v1H9zM10 9h1v1h-1zM11 9h1v1h-1zM1 10h1v1H1zM2 10h1v1H2zM3 10h1v1H3zM4 10h1v1H4zM9 10h1v1H9zM10 10h1v1h-1zM11 10h1v1h-1zM12 10h1v1h-1zM3 11h1v1H3zM10 11h1v1h-1z"/><path fill="#',
            getHair(tokenId),
            '" d="M3 3h1v1H3zM4 3h1v1H4zM5 3h1v1H5zM8 3h1v1H8zM2 4h1v1H2zM4 4h1v1H4zM8 4h1v1H8zM2 5h1v1H2zM4 5h1v1H4zM5 5h1v1H5zM9 5h1v1H9zM12 5h1v1h-1zM2 6h1v1H2zM3 6h1v1H3zM8 6h1v1H8zM9 6h1v1H9zM10 6h1v1h-1zM11 6h1v1h-1z"/><path fill="#',
            getHead(tokenId)
        ));
        svg = string(abi.encodePacked(
            svg, 
             '" d="M6 3h1v1H6zM7 3h1v1H7zM9 3h1v1H9zM3 4h1v1H3zM5 4h1v1H5zM6 4h1v1H6zM7 4h1v1H7zM9 4h1v1H9zM10 4h1v1h-1zM11 4h1v1h-1zM3 5h1v1H3zM6 5h1v1H6zM7 5h1v1H7zM8 5h1v1H8zM10 5h1v1h-1zM11 5h1v1h-1zM4 6h1v1H4zM5 6h1v1H5zM6 6h1v1H6zM7 6h1v1H7zM4 7h1v1H4zM5 7h1v1H5zM6 7h1v1H6zM7 7h1v1H7zM8 7h1v1H8zM9 7h1v1H9zM10 7h1v1h-1z"/><path fill="#', 
            getShirt(tokenId), 
            '" d="M5 8h1v1H5zM8 8h1v1H8zM5 9h1v1H5zM8 9h1v1H8zM5 10h1v1H5zM6 10h1v1H6zM7 10h1v1H7zM8 10h1v1H8zM4 11h1v1H4zM6 11h1v1H6zM7 11h1v1H7zM9 11h1v1H9zM4 12h1v1H4zM5 12h1v1H5zM6 12h1v1H6zM7 12h1v1H7zM8 12h1v1H8zM9 12h1v1H9zM3 13h1v1H3zM4 13h1v1H4zM5 13h1v1H5zM6 13h1v1H6zM7 13h1v1H7zM8 13h1v1H8zM9 13h1v1H9zM10 13h1v1h-1zM3 14h1v1H3zM4 14h1v1H4zM5 14h1v1H5zM8 14h1v1H8zM9 14h1v1H9zM10 14h1v1h-1z"/><path fill="#', 
            getButtons(tokenId), 
            '" d="M5 11h1v1H5zM8 11h1v1H8z"/><path fill="#', 
            getGloves(tokenId), 
            '" d="M1 11h1v1H1zM2 11h1v1H2zM11 11h1v1h-1zM12 11h1v1h-1zM1 12h1v1H1zM2 12h1v1H2zM3 12h1v1H3zM10 12h1v1h-1zM11 12h1v1h-1zM12 12h1v1h-1zM1 13h1v1H1zM2 13h1v1H2zM11 13h1v1h-1zM12 13h1v1h-1z"/><path fill="#',
            getShoes(tokenId),
            '" d="M2 15h1v1H2zM3 15h1v1H3zM4 15h1v1H4zM9 15h1v1H9zM10 15h1v1h-1zM11 15h1v1h-1z"/></svg>'
        ));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Mario #', Strings.toString(tokenId), '", "description": "PixelSuperMario is randomized mario generated and stored on chain. Feel free to use PixelSuperMario in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    // Step Pricing
    function price() public view returns (uint256) {
        return (totalSupply() / 1000 * BASE_PRICE);
    }

    function mint(uint256 amount) public payable nonReentrant {
        uint256 curPrice = price();
        require(amount * curPrice == msg.value, "Need pay");
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function withdraw() public {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}