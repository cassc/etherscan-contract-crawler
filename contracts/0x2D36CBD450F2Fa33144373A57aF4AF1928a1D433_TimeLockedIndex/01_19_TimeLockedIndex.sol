// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';

contract TimeLockedIndex is ERC721Enumerable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string private baseURI;

  address private admin;
  address public primaryMinter;

  mapping(address => bool) public minters;

  struct TimeLock {
    address token;
    uint256 amount;
    uint256 unlock;
  }

  mapping(uint256 => TimeLock) public timeLocks;
  //events
  event NFTCreated(
    uint256 indexed tokenId,
    address indexed recipient,
    address token,
    uint256 amount,
    uint256 unlock
  );
  event NFTRedeemed(uint256 indexed tokenId, address indexed holder, address token, uint256 amount);
  event URISet(string _uri);
  event MinterAdded(address newMinter);
  event MinterRemoved(address oldMinter);
  event PrimaryMinterChanged(address newMinter);

  constructor(string memory name, string memory symbol, address minter) ERC721(name, symbol) {
    admin = msg.sender;
    primaryMinter = minter;
    minters[minter] = true;
  }

  modifier onlyPrimaryMinter() {
    require(msg.sender == primaryMinter, '!primary');
    _;
  }

  function updateBaseURI(string memory _uri) external {
    require(msg.sender == admin, '!admin');
    baseURI = _uri;
    emit URISet(_uri);
  }

  function deleteAdmin() external {
    require(msg.sender == admin, "!admin");
    delete admin;
  }

  function addMinter(address minter) external onlyPrimaryMinter {
    minters[minter] = true;
    emit MinterAdded(minter);
  }

  function removeMinter(address minter) external onlyPrimaryMinter {
    delete minters[minter];
    emit MinterRemoved(minter);
  }

  function changePrimaryMinter(address _primaryMinter) external onlyPrimaryMinter {
    delete minters[primaryMinter];
    primaryMinter = _primaryMinter;
    minters[_primaryMinter] = true;
    emit PrimaryMinterChanged(_primaryMinter);
  }

  function createNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 unlock
  ) external nonReentrant returns (uint256) {
    require(validMint(msg.sender, token));
    require(validInput(recipient, amount, unlock));
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(recipient, newItemId);
    timeLocks[newItemId] = TimeLock(token, amount, unlock);
    emit NFTCreated(newItemId, recipient, token, amount, unlock);
    return newItemId;
  }

  function createNFTs(
    address[] memory recipients,
    address token,
    uint256[] memory amounts,
    uint256[] memory unlocks
  ) external nonReentrant {
    require(validMint(msg.sender, token));
    require(recipients.length == amounts.length && amounts.length == unlocks.length, 'array len');
    uint256 totalAmount;
    for (uint256 i; i < amounts.length; i++) {
      require(validInput(recipients[i], amounts[i], unlocks[i]));
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      totalAmount += amounts[i];
      _safeMint(recipients[i], newItemId);
      timeLocks[newItemId] = TimeLock(token, amounts[i], unlocks[i]);
      emit NFTCreated(newItemId, recipients[i], token, amounts[i], unlocks[i]);
    }
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
  }

  function redeemNFT(uint256 tokenId) external nonReentrant {
    require(ownerOf(tokenId) == msg.sender, '!owner');
    TimeLock memory tl = timeLocks[tokenId];
    require(tl.unlock < block.timestamp && tl.amount > 0, 'Not redeemable');
    _burn(tokenId);
    delete timeLocks[tokenId];
    TransferHelper.withdrawTokens(tl.token, msg.sender, tl.amount);
    emit NFTRedeemed(tokenId, msg.sender, tl.token, tl.amount);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function validInput(address recipient, uint256 amount, uint256 unlock) internal returns (bool) {
    require(recipient != address(0), 'zero address');
    require(amount > 0, 'zero amount');
    require(unlock > block.timestamp, '!future');
    return true;
  }

  function validMint(address minter, address token) internal returns (bool) {
    require(minters[minter], '!minter');
    require(token != address(0), 'zero_token');
    return true;
  }

  function lockedBalances(address holder, address token) public view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(holder, i);
      if (timeLocks[tokenId].token == token) lockedBalance += timeLocks[tokenId].amount;
    }
  }

  function isMinter(address minter) public view returns (bool) {
    return minters[minter];
  }
}