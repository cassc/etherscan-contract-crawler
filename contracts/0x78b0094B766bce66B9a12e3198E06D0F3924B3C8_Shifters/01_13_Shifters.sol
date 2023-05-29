// SPDX-License-Identifier: MIT
/** 
CROCS
*/

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shifters is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    uint256 public mintPrice = 230000000000000000;
    uint256 public preSalePrice = 220000000000000000;

    uint256 public collectionSize = 10000;
    uint256 public preSaleSize = 4500;

    string public baseUrl = "https://www.theshifters.io/nft/";

    bool public mintOn = false;
    bool public preSaleOn = false;

    constructor() ERC721("Shifters", "SHFTRZ") {}

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setPreSalePrice(uint256 price) public onlyOwner {
        preSalePrice = price;
    }

    function setSupply(uint256 supply) public onlyOwner {
        collectionSize = supply;
    }

    function setPreSaleSupply(uint256 supply) public onlyOwner {
        preSaleSize = supply;
    }
    
    function transferBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseUrl(string memory url) public onlyOwner {
        baseUrl = url;
    }

    function baseTokenURI() public view returns (string memory) {
      return baseUrl;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(
            baseTokenURI(),
            _tokenId.toString()
        ));
    }
    
    function togglePreSale() public onlyOwner {
        preSaleOn = !preSaleOn;
    }

    function toggleMint() public onlyOwner {
        mintOn = !mintOn;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokens = balanceOf(_owner);
        if (tokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokens);
            uint256 index;
            for (index = 0; index < tokens; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function createPreSaleShifter(uint256 quantity) public payable {
        
        require(preSaleOn, "Presale is not open");
        require(msg.value >= preSalePrice * quantity, "Value too low");
        require(quantity <= preSaleSize - totalSupply(), "Presale complete");
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < preSaleSize) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    function createShifter(uint256 quantity) public payable {
        
        require(mintOn, "Sale is not open");
        require(msg.value >= mintPrice * quantity, "Value too low");
        require(quantity <= collectionSize - totalSupply(), "Contract fullfilled");
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < collectionSize) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }  
}