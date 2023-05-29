//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Scumbags is ERC721Enumerable, Ownable {
  string public constant SCUM_PROVENANCE = "d415ae93d6ee3c92f1047669d0e88f6bda58b87dd06811938fc3aa247ae94cf9";
  uint256 public constant MAX_BAGS = 7777;
  uint public startingIndex;
  string public baseURI;
  bool public saleIsActive;
  mapping(address => bool) public hasClaimed;

  constructor() ERC721("Scumbags", "Scumbags") {}

  function claim() external {
    require(totalSupply() + 1 <= MAX_BAGS, "No scum left!");
    require(hasClaimed[msg.sender] == false, "You already claimed, scum!");

    _mint(msg.sender, totalSupply());

    if (totalSupply() == MAX_BAGS && startingIndex == 0) {
      startingIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % 1000;

      if (startingIndex == 0) {
        startingIndex = 69;
      }
    } 
  }

  function tenPack() payable external {
    require(totalSupply() + 10 <= MAX_BAGS,"No scum left!");
    require(msg.value >= 0.1 ether, "Incorrect ether sent!");

    uint currentSupply = totalSupply();

    for(uint i = 0; i < 10; i++) {
      _safeMint(msg.sender, currentSupply++);
    }

    if (totalSupply() == MAX_BAGS && startingIndex == 0) {
      startingIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % MAX_BAGS;

      if (startingIndex == 0) {
        startingIndex++;
      }
    } 
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setBaseURI(string calldata newURI) public onlyOwner {
    baseURI = newURI;
  }

  function lockstartingIndex() public onlyOwner {
    require(startingIndex == 0, 'Already locked');

    startingIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % MAX_BAGS;

    if(startingIndex == 0){
      startingIndex++;
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
}