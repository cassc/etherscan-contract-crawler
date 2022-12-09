// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract UkrainePups is ERC721A, Ownable {
  uint256 public price = 0.025 ether;
  uint256 constant maxSupply = 800;

  constructor() ERC721A("UkrainePups", "JYU") {}

  function mint(uint256 amount) public payable {
    address minter = _msgSender();
    require(_nextTokenId() + amount < maxSupply, "Sold out");
    require(tx.origin == minter, "Contracts not allowed");
    require(price * amount <= msg.value, "You must send enough eth");

    _mint(minter, amount);
  }

  function mintAsOwner(address to, uint8 amount) public onlyOwner {
    require(_nextTokenId() + amount < maxSupply, "Sold out");
    _mint(to, amount);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://api.junkyarddogs.io/ukraine/";
  }
}