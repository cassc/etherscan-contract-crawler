// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/ERC721HexURI.sol";

contract Inviteable is Ownable, ERC721HexURI, ERC721URIStorage {
  event InviteCreated(uint256 invite, uint8 generation);
  event InviteRedeemed(uint256 invite);

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  using SafeMath for uint8;
  using SafeMath for uint256;

  mapping(uint256 => bool) public redeemed;
  mapping(uint256 => uint8) public generation;
  mapping(uint256 => uint256) public parentInvite;

  uint256 private _numberOfChildren;
  uint256 private _numberOfGenerations;
  uint8 private _maxGenerations;
  uint8 private _redeemableGeneration;
  address private _owner;

  constructor(
    string memory name,
    string memory symbol,
    uint256 numberOfChildren,
    uint256 numberOfGenerations,
    uint256 initialInvites,
    uint8 initialRedeemableGenerations
  ) ERC721(name, symbol) {
    _numberOfChildren = numberOfChildren;
    _numberOfGenerations = numberOfGenerations - 1;
    _redeemableGeneration = initialRedeemableGenerations;
    _tokenIds._value = initialInvites;
    _owner = msg.sender;
    for (uint16 i; i < initialInvites; ++i) {
      _safeMint(_owner, i);
    }
  }

  function createInvites(uint256 parentId) private {
    if (generation[parentId] < _numberOfGenerations) {
      uint8 nextGen = generation[parentId] + 1;
      for (uint256 i; i < _numberOfChildren; ++i) {
        uint256 newItemId = _tokenIds.current();
        _safeMint(ownerOf(parentId), newItemId);
        parentInvite[newItemId] = parentId;
        generation[newItemId] = nextGen;
        _tokenIds.increment();
        emit InviteCreated(newItemId, nextGen);
      }
    }
  }

  function redeemInvite(uint256 tokenId) internal {
    redeemed[tokenId] = true;
    createInvites(tokenId);
    emit InviteRedeemed(tokenId);
  }

  function getRedeemableGeneration() public view returns (uint8) {
    return _redeemableGeneration;
  }

  function increaseReedemableGeneration() public onlyOwner {
    _redeemableGeneration += 1;
  }

  // ERC721URIStorage Overrides
  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721, ERC721URIStorage)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721HexURI, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}