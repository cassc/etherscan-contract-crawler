// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../tokens/rejuvenate/RejuvenateFinance.sol";

contract Staking is Pausable, Ownable, ReentrancyGuard {
  RejuvenateFinance public token;

  uint256 public rewardRate;
  uint256 internal lastUpdateBlock;
  uint256 internal rewardsPerToken;

  mapping(address => uint256) internal userRewardsPerToken;
  mapping(address => uint256) internal rewards;

  uint256 public totalStaked;
  mapping(address => uint256) internal balances;

  event Stake(address wallet, uint256 amount, uint256 staked);
  event Unstake(address wallet, uint256 amount, uint256 staked);

  constructor(address _token, uint256 _rewardRate) {
    token = RejuvenateFinance(_token);
    rewardRate = _rewardRate;
  }

  function changeRewardsPerBlock(uint256 _rewardRate) external onlyOwner {
    rewardRate = _rewardRate;
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalStaked == 0) {
      return 0;
    }
    return
      rewardsPerToken +
      ((rewardRate * (block.number - lastUpdateBlock) * 1e18) / totalStaked);
  }

  function earned(address _wallet) public view returns (uint256) {
    return
      ((balances[_wallet] * (rewardPerToken() - userRewardsPerToken[_wallet])) /
        1e18) + rewards[_wallet];
  }

  modifier updateReward(address _wallet) {
    rewardsPerToken = rewardPerToken();
    lastUpdateBlock = block.number;

    rewards[_wallet] = earned(_wallet);
    userRewardsPerToken[_wallet] = rewardsPerToken;
    _;
  }

  function stake(
    uint256 _amount
  ) external payable nonReentrant whenNotPaused updateReward(msg.sender) {
    totalStaked += _amount;
    balances[msg.sender] += _amount;
    IERC20(token).transferFrom(msg.sender, address(this), _amount);
    emit Stake(msg.sender, _amount, totalStaked);
  }

  function unstake(
    uint256 _amount
  ) external payable nonReentrant whenNotPaused updateReward(msg.sender) {
    require(balances[msg.sender] >= _amount, "Not enought staked");
    totalStaked -= _amount;
    balances[msg.sender] -= _amount;
    IERC20(token).transfer(msg.sender, _amount);
    emit Unstake(msg.sender, _amount, totalStaked);
  }

  function claimRewards()
    external
    payable
    whenNotPaused
    updateReward(msg.sender)
  {
    uint256 reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    token.mint(msg.sender, reward);
  }

  function compound()
    external
    payable
    nonReentrant
    whenNotPaused
    updateReward(msg.sender)
  {
    uint256 reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    totalStaked += reward;
    balances[msg.sender] += reward;
    token.mint(address(this), reward);
    emit Stake(msg.sender, reward, totalStaked);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function inCaseTokensGetStuck(address _token) external onlyOwner {
    require(_token != address(token), "!token");
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, amount);
  }
}