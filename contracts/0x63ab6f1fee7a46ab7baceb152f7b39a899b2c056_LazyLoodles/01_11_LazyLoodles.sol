// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LazyLoodles is ERC721, Ownable {
  bool public paused = true;
  bool public isPaidMint = true;
  string private _baseTokenURI;
  uint256 public totalSupply = 0;
  uint256 public constant price = 0.02 ether;
  uint256 public constant maxSupply = 5000;
  uint256 public constant maxFreeMints = 500;
  mapping(address => uint256) private freeWallets;

  constructor(string memory baseURI)
    ERC721("Lazy Loodles", "LL")
  {
    setBaseURI(baseURI);

    totalSupply = 55;

    for (uint256 i; i < 55; i++) {
      _mint(owner(), i);
    }
  }

  function mint(uint256 num) public payable {
    uint256 supply = totalSupply;

    require(!paused, "MINTING PAUSED");
    require(totalSupply + num <= maxSupply, "EXCEEDS MAX SUPPLY");

    if (totalSupply + num > maxFreeMints && isPaidMint) {
      require(num < 11, "MAX PER TRANSACTION IS 10");
      require(msg.value == price * num, "WRONG ETH AMOUNT SENT");
    } else {
      require(
        freeWallets[msg.sender] + num < 6,
        "MAX FREE MINTS PER WALLET IS 5"
      );

      freeWallets[msg.sender] += num;
    }

    totalSupply += num;

    for (uint256 i; i < num; i++) {
      _mint(msg.sender, supply + i);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _baseTokenURI = baseUri;
  }

  function pause(bool state) public onlyOwner {
    paused = state;
  }

  function paidMint(bool state) public onlyOwner {
    isPaidMint = state;
  }

  function withdrawAll() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "WITHDRAW UNSUCCESSFUL"
    );
  }
}