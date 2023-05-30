//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoctorDroolsMatterManipulator is ERC721A, Ownable {
  uint256 public constant MAX_NFTS = 1000;
  uint256 public constant PRICE = 0.1 ether;
  string public constant DDMM_PROVENANCE = "0xd46954b179896af7f3903cbee13075fe46331f9331d442e0b7ea4f7a3d965f16";
  string public baseURI;
  uint public sequenceOffset;
  bool public saleIsActive;

  constructor(string memory newBaseURI) ERC721A("DoctorDroolsMatterManipulator", "DDMM") {
    baseURI = newBaseURI;
  }

  receive() external payable {
    require(saleIsActive, "Sale must be active to mint");
    uint256 numToMint = msg.value / PRICE;
    require(numToMint <= 5, "Maximum 5 per transaction");
    require(totalSupply() + numToMint <= MAX_NFTS, "Purchase would exceed max supply");

    _mint(msg.sender, numToMint);
  }

  function experiment(uint amount, address _to) external onlyOwner {
    require(totalSupply() + amount <= MAX_NFTS, "Purchase would exceed max supply");

    _mint(_to, amount);
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newURI) public onlyOwner {
    baseURI = newURI;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}