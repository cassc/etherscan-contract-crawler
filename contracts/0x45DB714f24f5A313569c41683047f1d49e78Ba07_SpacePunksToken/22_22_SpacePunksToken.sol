pragma solidity ^0.8.0;

// SPDX-License-Identifier: LGPL-3.0-or-later

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SpacePunksToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public constant TOKEN_LIMIT = 10000;
  uint256 private _tokenPrice;
  uint256 private _maxTokensAtOnce = 1;

  bool public publicSale = false;
  bool public teamSale = false;

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  mapping(address => bool) private _teamSaleAddresses;
  uint256[] private _teamShares = [100];
  address[] private _team = [0x3515001548Cb3f93Dc5E3F3880D1f5ab2b0E07DB];

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("Space Punks", unicode"⚇")
  {
    setTokenPrice(60000000000000000);

    _teamSaleAddresses[0x3515001548Cb3f93Dc5E3F3880D1f5ab2b0E07DB] = true;
  }


  // Required overrides from parent contracts
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }


  // _tokenPrice
  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }

  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }

  // _paused
  function togglePaused() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }


  // _maxTokensAtOnce
  function getMaxTokensAtOnce() public view returns (uint256) {
    return _maxTokensAtOnce;
  }

  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    _maxTokensAtOnce = _count;
  }


  // Team and Public sales
  function enablePublicSale() public onlyOwner {
    publicSale = true;
    setMaxTokensAtOnce(20);
  }

  function disablePublicSale() public onlyOwner {
    publicSale = false;
    setMaxTokensAtOnce(1);
  }

  function toggleTeamSale() public onlyOwner {
    teamSale = !teamSale;
  }


  // Token URIs
  function _baseURI() internal override pure returns (string memory) {
    return "ipfs://QmVbg8tDifQfUTjB11tbSGsk93vXboPuV73ogLBf6MSJ7p/";
  }

  // Pick a random index
  function randomIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }

    nonce++;

    return value.add(1);
  }


  // Minting single or multiple tokens
  function _mintWithRandomTokenId(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  function mintToken() public payable nonReentrant whenNotPaused {
    require(totalSupply().add(1) <= TOKEN_LIMIT, "Purchase would exceed max supply of Space Punks");
    require(msg.value >= _tokenPrice, "Insufficient funds to purchase");

    if (!publicSale) {
      require (balanceOf(msg.sender) <= 1, "Only one token per address allowed");
    }

    _mintWithRandomTokenId(msg.sender);
  }

  function mintMultipleTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Purchase would exceed max supply of Space Punks");
    require(publicSale, "Public sale must be active to mint multiple tokens at once");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  function mintMultipleTokensForTeam(uint256 _amount) public payable nonReentrant {
    require(teamSale, "Team sale must be active to mint as a team member");
    require(totalSupply() < 100, "Exceeded tokens allocation for team members");
    require(_teamSaleAddresses[address(msg.sender)], "Not a team member");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }
}