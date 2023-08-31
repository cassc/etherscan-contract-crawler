//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Colornomics is ERC721URIStorage, Ownable, Pausable {    
    string public baseURI;    
    using Strings for uint256;
    using SafeMath for uint256;
    mapping(uint256 => bool) public colorsIsPicked;
    uint256 public mintPrice = 0.00167 ether;

    event Minted(
        address indexed minter,                
        uint256 indexed color
    );

    constructor() ERC721("Colornomics", "CLRN") {        
    }

    function _isValidColorHex(string memory tokenId) internal pure returns (bool) {
        bytes memory tokenIdBytes = bytes(tokenId);
        if (tokenIdBytes.length != 7) {
            return false;
        }
        if (tokenIdBytes[0] != 0x23) {
            return false; // The first character must be #
        }
        for (uint256 i = 1; i < tokenIdBytes.length; i++) {
            bytes1 char = tokenIdBytes[i];
            if (
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x46) && // A-F
                !(char >= 0x61 && char <= 0x66) // a-f
            ) {
                return false;
            }
        }
        return true;
    }

    function colorToDecimal(string memory hexValue) public pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 1; i < 7; i++) {
            uint8 digit = uint8(bytes(hexValue)[i]);
            if (digit >= 48 && digit <= 57) {
                result = result * 16 + (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result = result * 16 + (digit - 55);
            } else {
                result = result * 16 + (digit - 87);
            }
        }
        return result;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner{
        mintPrice = _mintPrice;
    }  

    function mint(string memory colorVal) public payable whenNotPaused {      
        require(msg.value >= mintPrice, "Should be paid enough for minting!");     
        require(_isValidColorHex(colorVal) == true, "Invalid color value format");              
        uint256 color = colorToDecimal(colorVal);
        require(colorsIsPicked[color] != true, "The color is already minted");    
        _mint(msg.sender, color);        
        colorsIsPicked[color] = true;
        emit Minted(msg.sender, color);        
    }

    function mintBatch(string[] memory colorVals) public payable whenNotPaused {      
        require(colorVals.length > 0, "Invalid Param");
        require(msg.value >= mintPrice * colorVals.length, "Should be paid enough for minting!"); 
        for (uint i=0; i< colorVals.length; i++){
            mint(colorVals[i]);
        }
    }

    // Withdraw contract ETH balance
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "no eth to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function IsColorPicked(uint256 color) public view returns (bool) {
        return colorsIsPicked[color];
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString())) : "";
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}