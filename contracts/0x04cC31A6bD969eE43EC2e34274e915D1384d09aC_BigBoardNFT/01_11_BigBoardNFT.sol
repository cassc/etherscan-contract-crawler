// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BigBoardNFT is ERC721, Ownable {
  bool private alreadyMinted;

  constructor() ERC721("Test NFT", "TSB") {}

  function mintTotalSupply(address to) public onlyOwner {
    require(alreadyMinted == false, "ERC721: Mint already executed");

    _mint(to, 1);
    _mint(to, 2);

    alreadyMinted = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://pixel.blockstars.tech/api/tokens/";
  }
}