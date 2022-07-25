// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BigBoardNFT is ERC721, Ownable {
  bool private alreadyMinted;

  constructor() ERC721("Big Board NFT", "BBNFT") {}

  function mintTotalSupply(address to) public onlyOwner {
    require(alreadyMinted == false, "ERC721: Mint already executed");

    for (uint256 i = 1; i < 1025; i++) {
      _mint(to, i);
    }

    alreadyMinted = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://bigboardnft.com/api/tokens/";
  }
}