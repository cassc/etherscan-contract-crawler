// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract xCollective is ERC721A, Ownable {
  uint256 public constant MAX_SUPPLY = 200;
  address internal constant MINTER = 0x17A743e37b114e26095c365Cc05Cd1581C1356Cb;
  string public constant baseURI =
    "ipfs://bafkreihqcie4teb4uooxkmez7lf4g7csvg3et442buivb3ugjmfkyqeelq";

  constructor() ERC721A("I support pay transparency in web3", "xCollective") {
    _transferOwnership(MINTER);
    _mint(MINTER, MAX_SUPPLY);
  }

  function mint(address to, uint256 quantity) external onlyOwner {
    _mint(to, quantity);
  }

  function contractURI() public pure returns (string memory) {
    return "ipfs://bafkreifncza2ihi6ra5nyiuz46q7pjhoebyth2pejtqjmjwlvijn4tz3v4";
  }

  function tokenURI(
    uint256 /* tokenId */
  ) public view virtual override returns (string memory) {
    return _baseURI();
  }

  function _baseURI() internal pure override returns (string memory) {
    return baseURI;
  }
}