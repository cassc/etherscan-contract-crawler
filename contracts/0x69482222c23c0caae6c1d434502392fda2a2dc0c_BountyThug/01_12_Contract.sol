// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract BountyThug is ERC721A, Ownable {
  bool public paused = true;
  string public baseURI;
  uint256 public constant maxMintAmount = 5;
  uint256 public constant maxSupply = 8000;
  uint256 public constant freeClaim = 1300;
  uint256 public constant cost = 0.035 ether; 


  constructor(string memory initBaseURI) ERC721A("BountyThug NFT", "BountyThug") {
    baseURI = initBaseURI;
  }

  modifier mintCompliance(uint256 _mintAmount){
    require(!paused, "Paused");
    require(tx.origin == msg.sender, "Only User");
    require(_mintAmount > 0 && _mintAmount <= 5, "Number is wrong");
    require(totalSupply() + _mintAmount <= maxSupply, "Total Supply Max");
    _;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

    function adminMint(address to,uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

  function mint(uint256 quantity) external payable mintCompliance(quantity) {
    require(numberMinted(msg.sender) + quantity <= maxMintAmount,"Had Mint");
    if (totalSupply()+quantity>2000){
      require(msg.value >= cost * quantity, "ETH is not enough");
    }
    _safeMint(msg.sender, quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

}