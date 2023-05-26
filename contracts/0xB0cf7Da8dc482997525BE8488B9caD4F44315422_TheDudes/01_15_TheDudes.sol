// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./TheDudesDNAFactory.sol";

contract TheDudes is ERC721Enumerable, TheDudesDNAFactory, Ownable {
  using SafeMath for uint256;
  using SafeMath for uint8;

  uint public maxDudes = 512;
  uint public maxDudesPerPurchase = 10;
  uint256 public price = 20000000000000000; // 0.020 Ether

  bool public isSaleActive = false;
  string public baseURI;
  mapping (uint => string) public dudes;

  address constant private creator = 0xC624ACB9861bbEa8DD37F3D0C1E49B7AB90B2Af4;

  constructor (uint _maxDudes, uint _maxDudesPerPurchase) ERC721("the dudes", "dude") {
    maxDudes = _maxDudes;
    maxDudesPerPurchase = _maxDudesPerPurchase;
    _claim(creator, 1, 873281);
  }

  function setIsSaleActive(bool _isSaleActive) public onlyOwner {
    isSaleActive = _isSaleActive;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function claim(uint256 _numDudes, uint _salt) public payable {
    require(isSaleActive, "dude, sale is not active!" );
    require(_numDudes > 0 && _numDudes <= maxDudesPerPurchase, 'You can get no fewer than 1, and no more than 10 dudes at a time');
    require(totalSupply().add(_numDudes) <= maxDudes, "Sorry too many dudes!");
    require(msg.value >= price.mul(_numDudes), "Ether value sent is not correct dude!");

    _claim(msg.sender, _numDudes, _salt);
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), "/", dudes[_tokenId]));
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function _claim(address _to, uint256 _numDudes, uint _salt) internal {
    for (uint256 i = 0; i < _numDudes; i++) {
      uint256 mintIndex = totalSupply();

      string memory dudeId = _getDNA(_salt * i);
      dudes[mintIndex] = dudeId;

      _safeMint(_to, mintIndex);
    }
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}