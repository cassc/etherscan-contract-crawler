// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Non-transferrable NFTs for HonestNFT Crypto Sleuth
 */

contract HonestNFTCrytpoSleuth is ERC721, ERC721Enumerable, Ownable {
  mapping(address => uint256) public allowlist;

  constructor() ERC721("HonestNFT Crypto Sleuth NFT (Non-transferrable)", "Crypto Sleuth") {}

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  /**
   * Override Open Zeppelin's tokenURI() since it concatenates tokenId to
   * baseURI by default, but in our case each token has the same metadata.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return _baseURI();
  }

  // Override required by Solidity.
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function mint() public {
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    allowlist[msg.sender]--;
    _safeMint(msg.sender, totalSupply()+1);
  }

  function setAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(addresses.length == numSlots.length,"addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  // Non-transferability
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(from == address(0), "Token is not transferable");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}