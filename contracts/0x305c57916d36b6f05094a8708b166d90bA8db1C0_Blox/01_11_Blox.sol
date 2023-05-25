// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGauntlet {
  function ownerOf(uint tokenId) external view returns (address owner);
}

contract Blox is ERC721, Ownable {
  constructor() ERC721("Blox", "BLX") {}

  string private uri = "https://assets.bossdrops.io/blox/";

  uint public constant MAX_TOKENS = 10000;

  IGauntlet gauntlets = IGauntlet(address(0x74EcB5F64363bd663abd3eF08dF75dD22d853BFC));
  
  uint public numMinted = 0;
  /**
   * Airdrop of blox will be called by owner after taking a snapshot of current token holders.
   */
  function mintMany(uint num) public onlyOwner {
    uint newTotal = numMinted + num;
    require(newTotal <= MAX_TOKENS, "Minting would exceed max allowed supply");
    while(numMinted < newTotal) {
        _mint(gauntlets.ownerOf(numMinted), numMinted);
        numMinted++;
    }
  }
  
  function setBaseURI(string memory baseURI) public onlyOwner {
    uri = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }
}