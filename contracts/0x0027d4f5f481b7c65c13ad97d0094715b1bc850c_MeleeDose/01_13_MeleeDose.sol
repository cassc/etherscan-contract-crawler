// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract MeleeDose is ERC721A, Ownable {
    using Strings for uint256;
    string baseURI;
    string public baseExtension = ".json";

    constructor(uint256 _maxBatchSize) ERC721A ("Melee Dose Genesis", "MDG", _maxBatchSize) {
    
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
     
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

     //Internal
    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
}