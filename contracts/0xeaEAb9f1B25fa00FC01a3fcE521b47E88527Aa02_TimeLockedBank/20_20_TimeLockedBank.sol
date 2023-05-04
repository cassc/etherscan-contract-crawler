// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '@openzeppelin/contracts/utils/Counters.sol';
import './ERC721Delegate/ERC721Delegate.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';

contract TimeLockedBank is ERC721Delegate, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  /// @dev baseURI is the URI directory where the metadata is stored
  string private baseURI;
  /// @dev bool to check if the uri has been set
  bool private uriSet;
  /// @dev admin for setting the baseURI;
  address private admin;

  /// @dev this contract only supports a single token
  address public token;
  struct TimeLock {
    uint256 amount;
    uint256 unlockDate;
  }

  mapping(uint256 => TimeLock) public timeLocks;
  //events
  event NFTCreated(uint256 indexed tokenId, address indexed recipient, uint256 amount, uint256 unlockDate);
  event NFTRedeemed(uint256 indexed tokenId, address indexed holder, uint256 amount);
  event NFTReLocked(uint256 indexed tokenId, address indexed holder, uint256 amount, uint256 unlockDate);
  event NFTLoaded(uint256 indexed tokenId, address indexed holder, uint256 amount, uint256 unlockDate);
  event NFTLockedAndLoaded(uint256 indexed tokenId, address indexed holder, uint256 amount, uint256 unlockDate);
  event URISet(string _uri);
  event AdminDeleted(address formerAdmin);

  constructor(string memory name, string memory symbol, address _token) ERC721(name, symbol) {
    token = _token;
    admin = msg.sender;
  }

  function updateBaseURI(string memory _uri) external {
    require(msg.sender == admin, 'ADMIN');
    baseURI = _uri;
    uriSet = true;
    emit URISet(_uri);
  }

  function deleteAdmin() external {
    require(msg.sender == admin, 'ADMIN');
    require(uriSet, 'not set');
    delete admin;
    emit AdminDeleted(msg.sender);
  }

  function createNFT(address recipient, uint256 amount, uint256 unlockDate) external nonReentrant returns (uint256) {
    require(recipient != address(0), 'zero address');
    require(amount > 0, 'zero amount');
    require(unlockDate < block.timestamp + 1100 days, 'day guardrail');
    require(unlockDate > block.timestamp, '!future');
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(recipient, newItemId);
    timeLocks[newItemId] = TimeLock(amount, unlockDate);
    emit NFTCreated(newItemId, recipient, amount, unlockDate);
    return newItemId;
  }

  function redeemNFT(uint256 tokenId) external nonReentrant {
    require(ownerOf(tokenId) == msg.sender, '!owner');
    TimeLock memory tl = timeLocks[tokenId];
    require(tl.unlockDate < block.timestamp && tl.amount > 0, 'Not redeemable');
    _burn(tokenId);
    delete timeLocks[tokenId];
    TransferHelper.withdrawTokens(token, msg.sender, tl.amount);
    emit NFTRedeemed(tokenId, msg.sender, tl.amount);
  }

  function relockNFT(uint256 tokenId, uint relockDate) external nonReentrant {
    require(ownerOf(tokenId) == msg.sender, '!owner');
    require(relockDate < block.timestamp + 1100 days, 'day guardrail');
    TimeLock storage tl = timeLocks[tokenId];
    require(relockDate > tl.unlockDate && relockDate > block.timestamp, 'unlock error');
    tl.unlockDate = relockDate;
    emit NFTReLocked(tokenId, msg.sender, tl.amount, relockDate);
  }

  function loadNFT(uint256 tokenId, uint256 additionalAmount) external nonReentrant {
    TimeLock storage tl = timeLocks[tokenId];
    require(tl.amount > 0, 'token redeemed');
    require(additionalAmount > 0, 'no load');
    TransferHelper.transferTokens(token, msg.sender, address(this), additionalAmount);
    tl.amount += additionalAmount;
    emit NFTLoaded(tokenId, msg.sender, tl.amount, tl.unlockDate);
  }

  function locknLoadNFT(uint256 tokenId, uint256 additionalAmount, uint256 relockDate) external nonReentrant {
    require(ownerOf(tokenId) == msg.sender, '!owner');
    require(relockDate < block.timestamp + 1100 days, 'day guardrail');
    TimeLock storage tl = timeLocks[tokenId];
    require(relockDate > tl.unlockDate && relockDate > block.timestamp, 'unlock error');
    require(additionalAmount > 0, 'no load');
    TransferHelper.transferTokens(token, msg.sender, address(this), additionalAmount);
    tl.amount += additionalAmount;
    tl.unlockDate = relockDate;
    emit NFTLockedAndLoaded(tokenId, msg.sender, tl.amount, tl.unlockDate);
  }

  function delegateNFT(address delegate, uint256 tokenId) external {
    _delegateToken(delegate, tokenId);
  }

  /// @dev internal function used by the standard ER721 function tokenURI to retrieve the baseURI privately held to visualize and get the metadata
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @dev lockedBalances is a function that will enumarate all of the tokens of a given holder, and aggregate those balances up
  /// this is useful for snapshot voting and other view methods to see the total balances of a given user for a single token
  /// @param holder is the owner of the NFTs
  function lockedBalances(address holder) public view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 tokenId = _tokenOfOwnerByIndex(holder, i);
      lockedBalance += timeLocks[tokenId].amount;
    }
  }

  /// @dev delegatedBAlances is a function that will enumarate all of the tokens of a given delagate, and aggregate those balances up
  /// this is useful for snapshot voting and other view methods to see the total balances of a given user for a single token
  /// @param delegate is the wallet that has been delegated NFTs
  function delegatedBalances(address delegate) public view returns (uint256 delegatedBalance) {
    uint256 delegateBalance = balanceOfDelegate(delegate);
    for (uint256 i; i < delegateBalance; i++) {
      uint256 tokenId = tokenOfDelegateByIndex(delegate, i);
      delegatedBalance += timeLocks[tokenId].amount;
    }
  }
}