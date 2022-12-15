// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC4973O} from './ERC4973O.sol';
import {BitMaps} from '@openzeppelin/contracts/utils/structs/BitMaps.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

bytes32 constant AUCTION_HASH = keccak256('Auction(address active,address passive,uint256 bid)');

struct Stats {
  uint216 bidAmount;
  uint16 bidCount;
  uint16 tokenIndex;
  bool refundClaimed;
}

contract OldeusAuction is ERC4973O, Ownable, Pausable, ReentrancyGuard {
  using BitMaps for BitMaps.BitMap;
  using ECDSA for bytes32;
  using Strings for uint16;

  mapping(uint256 => Stats) private _stats;

  uint64 public entryPrice;
  uint64 public minBid;
  uint64 public tokenIndex;

  uint64 public openTime;
  uint96 public finalPrice;
  uint96 public closeTime;

  address public issuer;
  address public oldeusOrigins;
  string private _baseURI;

  event Take(address indexed to, uint256 indexed tokenId);
  event Raise(uint256 indexed tokenId, uint256 indexed totalBid);

  modifier onlyOldeusOrigins() {
    require(oldeusOrigins != address(0), "onlyOldeusOrigins: address can't be zero address");
    require(msg.sender == oldeusOrigins, 'onlyOldeusOrigins: unauthorized');
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    string memory version_,
    address issuer_,
    uint64 entryPrice_,
    uint64 minBid_,
    uint64 openTime_,
    uint96 closeTime_
  ) ERC4973O(name_, symbol_, version_) {
    issuer = issuer_;
    entryPrice = entryPrice_;
    minBid = minBid_;
    openTime = openTime_;
    closeTime = closeTime_;
  }

  modifier whenLive() {
    require(block.timestamp >= openTime, "whenLive: auction hasn't opened");
    require(block.timestamp <= closeTime, 'whenLive: auction has closed');
    _;
  }

  function take(address from, bytes calldata signature) external payable whenLive whenNotPaused returns (uint256) {
    require(from == issuer, 'take: from must be Oldeus');
    require(msg.value >= entryPrice, 'take: insufficient funds');

    uint256 tokenId = _take(from, signature);
    Stats storage stats_ = _stats[tokenId];
    stats_.bidCount = 1;
    stats_.bidAmount = uint216(msg.value);
    stats_.tokenIndex = uint16(++tokenIndex);
    emit Take(msg.sender, tokenId);

    return tokenId;
  }

  function raise(bytes calldata signature) external payable whenLive whenNotPaused {
    require(msg.value >= minBid, 'raise: insufficient funds');
    uint256 tokenId = _safeCheckAgreement(msg.sender, issuer, msg.value, signature);

    require(msg.value >= minBid, 'raise: insufficient funds');
    require(_exists(tokenId), "raise: token doesn't exist");

    Stats storage stats_ = _stats[tokenId];
    ++stats_.bidCount;
    stats_.bidAmount += uint216(msg.value);

    emit Raise(tokenId, stats_.bidAmount);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(bytes(_baseURI).length > 0, "tokenURI: baseURI isn't set");
    require(_exists(tokenId), "tokenURI: token doesn't exist");

    return string.concat(_baseURI, _stats[tokenId].tokenIndex.toString());
  }

  function stats(uint256 tokenId) external view returns (Stats memory) {
    require(_exists(tokenId), "stats: token doesn't exist");

    return _stats[tokenId];
  }

  function stats(address holder) external view returns (Stats memory) {
    uint256 tokenId = uint256(_getHash(holder, issuer));
    require(_exists(tokenId), "stats: token doesn't exist");

    return _stats[tokenId];
  }

  function refund(bytes calldata signature) external nonReentrant {
    require(block.timestamp > closeTime, 'refund: auction not closed');
    require(finalPrice > 0, 'refund: final price not set');

    uint256 tokenId = _safeCheckAgreement(msg.sender, issuer, signature);
    Stats storage stats_ = _stats[tokenId];
    require(!stats_.refundClaimed, 'refund: claimed');
    require(stats_.bidAmount < finalPrice, 'refund: bidder has won');

    address payable recipient = payable(msg.sender);
    recipient.transfer(stats_.bidAmount);
    stats_.refundClaimed = true;
  }

  function refund(address payable to, uint256 refundAmount) external onlyOldeusOrigins nonReentrant {
    require(finalPrice > 0, 'refund: final price not set');
    uint256 tokenId = uint256(_getHash(to, issuer));
    Stats storage stats_ = _stats[tokenId];
    require(!stats_.refundClaimed, 'refund: claimed');
    require(refundAmount < stats_.bidAmount, 'refund: insufficient bid');
    to.transfer(refundAmount);
    stats_.refundClaimed = true;
  }

  function exists(address holder) external view returns (bool) {
    uint256 tokenId = uint256(_getHash(holder, issuer));
    return _exists(tokenId);
  }

  function tokenId(address holder) external view returns (uint256) {
    uint256 tokenId = uint256(_getHash(holder, issuer));
    return tokenId;
  }

  function withdraw(address payable to) external onlyOwner {
    require(to != address(0), "withdraw: address can't be zero address");

    address contractAddress = address(this);
    to.transfer(contractAddress.balance);
  }

  function migrate(address from, address to) external onlyOwner {
    uint256 tokenIdFrom = uint256(_getHash(from, issuer));
    require(_exists(tokenIdFrom), 'migrate: no token exists');
    uint256 tokenIdTo = uint256(_getHash(to, issuer));
    require(!_usedHashes.get(tokenIdTo), 'migrate: token exists');

    _stats[tokenIdTo] = _stats[tokenIdFrom];
    delete _stats[tokenIdFrom];
    _mint(issuer, to, tokenIdTo);
    _burn(tokenIdFrom);
  }

  function setAuctionTimes(uint256 openTime_, uint256 closeTime_) external onlyOwner {
    openTime = uint64(openTime_);
    closeTime = uint64(closeTime_);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function setEntryPrice(uint256 entryPrice_) external onlyOwner {
    entryPrice = uint64(entryPrice_);
  }

  function setMinBid(uint256 minBid_) external onlyOwner {
    minBid = uint64(minBid_);
  }

  function setIssuer(address issuer_) external onlyOwner {
    require(issuer_ != address(0), "setIssuer: address can't zero address");

    issuer = issuer_;
  }

  function setFinalPrice(uint256 finalPrice_) external onlyOwner {
    require(finalPrice_ != 0, "setFinalPrice: final price can't be zero");

    finalPrice = uint64(finalPrice_);
  }

  function setOldeusOrigins(address oldeusOrigins_) external onlyOwner {
    require(oldeusOrigins_ != address(0), "setOldeusOrigins: address can't zero address");
    oldeusOrigins = oldeusOrigins_;
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function _take(address from, bytes calldata signature) internal override returns (uint256) {
    require(msg.sender != from, "_take: can't take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, msg.value, signature);
    require(!_usedHashes.get(tokenId), '_take: id already used');
    _mint(from, msg.sender, tokenId);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function _safeCheckAgreement(address active, address passive, uint256 bid, bytes calldata signature) internal view returns (uint256) {
    bytes32 transactionHash = _getHash(active, passive, bid);
    require(SignatureChecker.isValidSignatureNow(passive, transactionHash, signature), '_safeCheckAgreement: invalid signature');

    bytes32 hash = _getHash(active, passive);
    uint256 tokenId = uint256(hash);
    return tokenId;
  }

  function _getHash(address active, address passive, uint256 bid) internal view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(AUCTION_HASH, active, passive, bid));

    return _hashTypedDataV4(structHash);
  }
}