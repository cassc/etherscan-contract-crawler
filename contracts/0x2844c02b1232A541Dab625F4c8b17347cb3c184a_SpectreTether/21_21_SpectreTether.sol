// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC4973} from './interfaces/ERC4973.sol';
import {ERC4973O} from './ERC4973O.sol';
import {ITether, Link} from './interfaces/Tether.sol';
import {BitMaps} from '@openzeppelin/contracts/utils/structs/BitMaps.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpectreTether is ITether, ERC4973O, Ownable, Pausable, ReentrancyGuard {
  using BitMaps for BitMaps.BitMap;
  using ECDSA for bytes32;
  using Strings for uint64;


  mapping(uint256 => Link) private _links;

  uint64 public tokenIndex;
  uint64 public validityPeriod;

  address public passContract;
  string private _baseURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory version_,
    address passContract_,
    uint64 validityPeriod_
  ) ERC4973O(name_, symbol_, version_) {
    passContract = passContract_;
    validityPeriod = validityPeriod_;
  }

  modifier onlySpectre(address holder) {
    require(IERC721(passContract).balanceOf(holder) > 0, "onlySpectre: need NFT");
    _;
  }

  function take(address from, bytes calldata signature) external payable onlySpectre(from) whenNotPaused returns (uint256) {
    uint256 tokenId = _take(from, signature);
    Link storage link = _links[tokenId];

    link.tokenIndex = ++tokenIndex;
    link.expiration = uint192(block.timestamp + validityPeriod);
    link.holder = from;
    emit Tether(from, msg.sender, tokenId);
    return tokenId;
  }

  function give(address to, bytes calldata signature) external payable onlySpectre(msg.sender) whenNotPaused returns (uint256) {
    uint256 tokenId = _give(to, signature);
    Link storage link = _links[tokenId];

    link.tokenIndex = ++tokenIndex;
    link.expiration = uint192(block.timestamp + validityPeriod);
    link.holder = msg.sender;
    emit Tether(msg.sender, to, tokenId);
    return tokenId;
  }

  function unequip(uint256 tokenId) public override(ERC4973O, IERC4973) {
    require(_exists(tokenId), 'unequip: token not found');
    Link storage link = _links[tokenId];
    require(ownerOf(tokenId) == msg.sender || link.holder == msg.sender, 'unequip: must be holder or owner');
    _usedHashes.unset(tokenId);
    _burn(tokenId);
    emit Untether(link.holder, msg.sender);
    delete _links[tokenId];
  }

  function refresh(uint256 tokenId, uint256 validityPeriod_) external {
    require(_exists(tokenId), "refresh: token not found");
    Link storage link = _links[tokenId];
    require(msg.sender == link.holder, "refresh: not owner");
    link.expiration = uint192(block.timestamp + validityPeriod_);
  }

  function isActive (uint256 tokenId) external view returns (bool) {
    return _exists(tokenId) && block.timestamp < _links[tokenId].expiration ;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(bytes(_baseURI).length > 0, "tokenURI: baseURI isn't set");
    require(_exists(tokenId), "tokenURI: token doesn't exist");

    return string.concat(_baseURI, _links[tokenId].tokenIndex.toString());
  }

  function exists(address active, address passive) external view returns (bool) {
    uint256 tokenId = uint256(_getHash(active, passive));
    return _exists(tokenId);
  }

  function tokenId(address active, address passive) external view returns (uint256) {
    uint256 tokenId = uint256(_getHash(active, passive));
    return tokenId;
  }

  function links(uint256 tokenId) external whenNotPaused view returns (Link memory) {
    require(_exists(tokenId), "links: token not found");
    return _links[tokenId];
  }

  function withdraw(address payable to) external onlyOwner {
    require(to != address(0), "withdraw: address can't be zero address");

    address contractAddress = address(this);
    to.transfer(contractAddress.balance);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}