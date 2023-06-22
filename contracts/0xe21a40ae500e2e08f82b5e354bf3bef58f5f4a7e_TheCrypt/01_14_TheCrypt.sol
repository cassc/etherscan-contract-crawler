/*
▒███████▒ ▒█████    ███▄ ▄███▓  ▄▄▄▄     ██▓█████
▒ ▒ ▒ ▄▀░▒██▒  ██▒ ▓██▒▀█▀ ██▒ ▓█████▄ ▒▓██▓█   ▀
░ ▒ ▄▀▒░ ▒██░  ██▒ ▓██    ▓██░ ▒██▒ ▄██░▒██▒███
  ▄▀▒   ░▒██   ██░ ▒██    ▒██  ▒██░█▀   ░██▒▓█  ▄
▒███████▒░ ████▓▒░▒▒██▒   ░██▒▒░▓█  ▀█▓ ░██░▒████
░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░░ ▒░   ░  ░░░▒▓███▀▒ ░▓ ░░ ▒░
░ ▒ ▒ ░ ▒  ░ ▒ ▒░ ░░  ░      ░░▒░▒   ░   ▒  ░ ░
░ ░ ░ ░ ░░ ░ ░ ▒   ░      ░     ░    ░   ▒    ░
  ░ ░        ░ ░  ░       ░   ░ ░        ░    ░
   ▄████▄  ██▀███  ▓██   ██▓ ██▓███  ▄▄▄█████▓
  ▒██▀ ▀█ ▓██ ▒ ██▒ ▒██  ██▒▓██░  ██ ▓  ██▒ ▓▒
  ▒▓█    ▄▓██ ░▄█ ▒  ▒██ ██░▓██░ ██▓▒▒ ▓██░ ▒░
  ▒▓▓▄ ▄██▒██▀▀█▄    ░ ▐██▓░▒██▄█▓▒ ▒░ ▓██▓ ░
  ▒ ▓███▀ ░██▓ ▒██▒  ░ ██▒▓░▒██▒ ░  ░  ▒██▒ ░
  ░ ░▒ ▒  ░ ▒▓ ░▒▓░   ██▒▒▒ ▒▓▒░ ░  ░  ▒ ░░
    ░  ▒    ░▒ ░ ▒░ ▓██ ░▒░ ░▒ ░         ░
  ░          ░   ░  ▒ ▒ ░░  ░░         ░ ░
  ░ ░        ░      ░ ░
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TheCrypt is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  // Vault and $FLESH addresses
  address public zombiezAddress;
  address public fleshAddress;

  // $FLESH rewards expiration
  uint256 public expiration;

  // Rate governs how often you receive $FLESH
  uint256 public rewardRate;

  // Track staked zombiez and last reward date
  mapping(address => EnumerableSet.UintSet) private _deposits;
  mapping(address => mapping(uint256 => uint256)) public _lastClaimBlocks;

  constructor(address _zombiezAddress, address _fleshAddress, uint256 _rewardRate, uint256 _expiration) {
    zombiezAddress = _zombiezAddress;
    fleshAddress = _fleshAddress;
    rewardRate = _rewardRate;
    expiration = block.number + _expiration;
    _pause();
  }

  // List staked Zombiez
  function depositsOf(address account) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  // Calculate reward for all staked Zombiez
  function calculateRewards(address account, uint256[] memory tokenIds) public view returns (uint256[] memory rewards) {
    rewards = new uint256[](tokenIds.length);

    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      rewards[i] = rewardRate * (_deposits[account].contains(tokenId) ? 1 : 0) * (Math.min(block.number, expiration) - _lastClaimBlocks[account][tokenId]);
    }

    return rewards;
  }

  // Calculate reward for specific Zombiez
  function calculateReward(address account, uint256 tokenId) public view returns (uint256) {
    require(Math.min(block.number, expiration) > _lastClaimBlocks[account][tokenId], "staking rewards have ended");
    return rewardRate * (_deposits[account].contains(tokenId) ? 1 : 0) * (Math.min(block.number, expiration) - _lastClaimBlocks[account][tokenId]);
  }

  // Claim rewards for all staked Zombiez
  function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
    uint256 reward;
    uint256 blockCur = Math.min(block.number, expiration);

    for (uint256 i; i < tokenIds.length; i++) {
      reward += calculateReward(msg.sender, tokenIds[i]);
      _lastClaimBlocks[msg.sender][tokenIds[i]] = blockCur;
    }

    if (reward > 0) {
      IERC20(fleshAddress).transfer(msg.sender, reward);
    }
  }

  // Stake Zombiez (deposit ERD721)
  function deposit(uint256[] calldata tokenIds) external whenNotPaused {
    require(msg.sender != zombiezAddress, "invalid address for staking");
    claimRewards(tokenIds);

    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(zombiezAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
      _deposits[msg.sender].add(tokenIds[i]);
    }
  }

  // Unstake Zombiez (withdrawal ERC721)
  function withdraw(uint256[] calldata tokenIds) external whenNotPaused nonReentrant() {
    claimRewards(tokenIds);
    for (uint256 i; i < tokenIds.length; i++) {
      require( _deposits[msg.sender].contains(tokenIds[i]), "zombie not staked or not owned");
      _deposits[msg.sender].remove(tokenIds[i]);
      IERC721(zombiezAddress).safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
    }
  }

  // (Owner) Withdrawal FLESH
  function withdrawTokens() external onlyOwner {
    uint256 tokenSupply = IERC20(fleshAddress).balanceOf(address(this));
    IERC20(fleshAddress).transfer(msg.sender, tokenSupply);
  }

  // (Owner) Set a multiplier for how many tokens to earn each time a block passes.
  function setRate(uint256 _rewardRate) public onlyOwner() {
    rewardRate = _rewardRate;
  }

  // (Owner) Set this to a block to disable the ability to continue accruing tokens past that block number.
  function setExpiration(uint256 _expiration) public onlyOwner() {
    expiration = block.number + _expiration;
  }

  // (Owner) Public accessor methods for pausing
  function pause() public onlyOwner { _pause(); }
  function unpause() public onlyOwner { _unpause(); }

  // Support ERC721 transfer
  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}