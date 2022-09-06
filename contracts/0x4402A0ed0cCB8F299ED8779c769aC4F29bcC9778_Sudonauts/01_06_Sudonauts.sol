// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Sudonauts is Ownable, ERC721A {
  constructor() ERC721A("Sudonauts", "SUDONAUTS") {}

  function devMint()
    external
    onlyOwner
  {
    _safeMint(msg.sender, 2000);
  }



  // // metadata URI
  string public _baseTokenURI;


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function transferToVault(address newOwner) public virtual onlyOwner {
    transferOwnership(newOwner);
  }
}