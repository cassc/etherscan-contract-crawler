// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ToonzRewardsCard is ERC721, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  string private _tokenURI;
  Counters.Counter private _tokenId;

  constructor() ERC721("Toonz Minter Rewards Card", "MINTR") {}

  function totalSupply() public view returns (uint) {
    return _tokenId.current();
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(_tokenURI).length > 0 ? _tokenURI : "";
  }

  function giftCard(address[] calldata _recipients) public onlyOwner {
    uint _amount = _recipients.length;
    for (uint i = 0; i < _amount; i++) {
      _tokenId.increment();
      _safeMint(_recipients[i], _tokenId.current());
    }
  }

  function setTokenURI(string memory _newTokenURI) public onlyOwner {
    _tokenURI = _newTokenURI;
  }

}