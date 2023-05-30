// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BabyMonkes is ERC721Enumerable, Ownable {
  string public baseTokenURI;
  address private monkesAddress;

  modifier onlyMonkesAddress() {
    require(msg.sender == monkesAddress, "Not monkes address");
    _;
  }

  constructor(string memory baseURI) ERC721("BabyMonkes", "BABYMONKE") {
    setBaseURI(baseURI);
  }

  function mint(address _to) public onlyMonkesAddress {
    _safeMint(_to, totalSupply() + 1);
  }

  function walletOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }

    return tokensId;
  }

  function setMonkesAddress(address _monkesAddress) public onlyOwner {
    monkesAddress = _monkesAddress;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }
}