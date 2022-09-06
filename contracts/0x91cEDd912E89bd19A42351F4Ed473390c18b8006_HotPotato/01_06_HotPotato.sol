// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract HotPotato is ERC721A, Ownable {
    uint256 MAX_SUPPLY = 100;
    uint256 maxMintAmountPerTx = 1;
    bool public paused = true;

    string public uriPrefix = "ipfs://QmViqZbmPBQzMFKem1kyh2Jx6YwsTeUqcL8JBBf445Yz9U/0.json";

    constructor() ERC721A("Hot Potato", "HOTP") {}

    

    modifier mintCompliance(uint256 quantity) {
        require(!paused, 'The contract is paused!');
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

     _;
  }

  function freeMint(uint256 quantity) public  mintCompliance(quantity) {
    require(!paused, 'The contract is paused!');
    require(quantity > 0 && quantity <= maxMintAmountPerTx, 'Invalid mint amount!');
    _safeMint(_msgSender(), quantity);
    }

    function mintForAddress(uint256 quantity, address _receiver)  public mintCompliance(quantity) onlyOwner{
        _safeMint(_receiver, quantity);
    }

    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        return uriPrefix;
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
}