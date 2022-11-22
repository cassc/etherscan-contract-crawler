// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Nft is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseURI;
  string public extension = ".json";
  uint256 public maxsupply = 1;
 
  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function mint(uint256 _amount)  external onlyOwner {
    uint256 totalSupply = totalSupply();
    require(_amount > 0, "need to mint at least 1 NFT");
    require(_amount + totalSupply <= maxsupply, "max mint amount per session exceeded");
   
    for (uint256 i = 1; i <= _amount; i++) {
      _safeMint(msg.sender, totalSupply + i);
      
    }
  }

  function tokenOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    return bytes(_baseURI()).length > 0
        ? string(abi.encodePacked(_baseURI(), tokenId.toString(), extension))
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    extension = _newBaseExtension;
  }
  
}