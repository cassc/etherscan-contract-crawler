// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTeamMATESAllen is Ownable, ERC721A {
  // Contract Constants
  uint128 public constant maxSupply = 325;
  
  // Timestamps
  uint128 public saleStartTime;

  // Contract Vars
  uint128 public teamClaimed;
  string public baseURI;
  
  uint128 price = .036 ether;

  modifier canMint(uint8 _amount, uint256 _value){
      require(totalSupply() + _amount <= maxSupply, "Quantity requested exceeds max supply.");
      require(tx.origin == msg.sender, "The caller is another contract.");
      require(block.timestamp >= saleStartTime, "Sale has not started yet.");
      require(_value >= price * _amount, "Not enough eth being sent!");
      _;
  }

  constructor(uint128 _saleStartTime) ERC721A("NFTeamMATESAllen", "NTMA") {
    saleStartTime = _saleStartTime;
  }

  function mint(address _recipient, uint8 _amount) external payable canMint(_amount, msg.value) {
    _mint(_recipient, _amount);
  }

  function teamClaim(uint128 _amount) external onlyOwner {
    require(teamClaimed + _amount <= 5, "Team has already claimed.");
    _mint(msg.sender, _amount);
    teamClaimed += _amount;
  }

  // Functions for testing
  function setSaleStartTime(uint128 _saleStartTime) external onlyOwner {
    saleStartTime = _saleStartTime;
  }

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setPrice(uint128 _price) external onlyOwner {
    price = _price;
  }
  
  function getPrice() public view returns (uint128) {
    return price;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));   
    }
}