// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract SudoCuteos is ERC721A, Ownable {
    uint256 MAX_SUPPLY = 500;
    bool public paused = true;

    string public uriPrefix = "ipfs://bafybeiazpeexy7fz4kmc5cdkfxhyv2cucvhdbmvxipn43meqfrlridu6bi/";
    string public uriSuffix = '.json';

    constructor() ERC721A("Sudo Cuteos", "CUTEOS") {}

    modifier mintCompliance(uint256 quantity) {
        require(!paused, 'The contract is paused!');
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
     _;
  }

    function mintForAddress(uint256 quantity, address _receiver)  public mintCompliance(quantity) onlyOwner{
        _safeMint(_receiver, quantity);
    }

    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? 
        string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix)) : "";
  }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

      function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

    function _baseURI() internal view override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
      function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
      }
}