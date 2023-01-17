// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStakingWallet.sol";
import 'hardhat/console.sol';

contract StakingContract is Ownable, Pausable, ReentrancyGuard {

  struct StakerInfo {
    uint256 amount;
    uint256 startTime;
    uint256 stakeRewards;
  }

  struct RateInfo {
    uint256 apy; // in percent, 10%
    uint256 startBlock;
  }
  IStakingWallet public rewardWallet;
  IStakingWallet public depositWallet;

  uint256 public stakeFee; 
  uint256 public maxStake = 500_000_000 * 10 **9; // 0.5% max supply
  address public feeReceiver;

  // Staker Info
  mapping(address => StakerInfo) public staker;

  uint256 public constant YEAR_SECOND = 31577600;
  IERC20 public immutable teletreonToken;
  RateInfo[] public rate;

  event LogStake(address indexed from, uint256 amount);
  event LogUnstake(address indexed from, uint256 amount, uint256 amountRewards);
  event LogRewardsWithdrawal(address indexed to, uint256 amount);
  event LogTokenRecovery(address tokenRecovered, uint256 amount);
  event LogChangeRewardWallet(IStakingWallet _old, IStakingWallet _new);
  event LogChangeDepositWallet(IStakingWallet _old, IStakingWallet _new);
  event LogFillReward(address filler, uint256 amount);
  event LogChangeRate(address changer, uint256 newRate);

  constructor(
    IERC20 _teletreonToken,
    uint256 _rate
  ) {
    teletreonToken = _teletreonToken;
    rate.push(RateInfo(_rate, block.timestamp));
  }

  function setRewardWallet(IStakingWallet _addr) external onlyOwner {
    emit LogChangeRewardWallet(rewardWallet, _addr);
    rewardWallet = _addr;
  }

  function setRate(uint256 _newRate) external onlyOwner {
    emit LogChangeRate(msg.sender, _newRate);
    rate.push(RateInfo(_newRate, block.timestamp));
  }

  function setFeeReceiver(address _addr) external onlyOwner {
    feeReceiver = _addr;
  }

  function setStakeFee(uint256 _fee) external onlyOwner {
    stakeFee = _fee;
  }

  function setMaxStake(uint256 _maxStake) external onlyOwner {
    maxStake = _maxStake;
  }

  function setDepositWallet(IStakingWallet _addr) external onlyOwner {
    emit LogChangeDepositWallet(depositWallet, _addr);
    depositWallet = _addr;
  }

  function stake(uint256 _amount) external whenNotPaused {
    require(address(rewardWallet) != address(0), "Reward Wallet not Set");
    require(address(depositWallet) != address(0), "Deposit Wallet not Set");
    // require(_amount > 100 && _amount < maxStake, "Forbidden Amount");
    require(teletreonToken.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance.");
    require(teletreonToken.balanceOf(msg.sender) >= _amount, "Insufficient teletreonToken balance");
    if (staker[msg.sender].amount > 0) {
      staker[msg.sender].stakeRewards = getTotalRewards(msg.sender);
    } 

    require(teletreonToken.transferFrom(msg.sender, address(this), _amount), "Transferfrom Failed");
    if(teletreonToken.allowance(address(this), address(depositWallet)) < _amount) {
      teletreonToken.approve(address(depositWallet), type(uint256).max);
    }
    
    depositWallet.deposit(msg.sender, _amount);
   
    staker[msg.sender].amount += _amount;
    staker[msg.sender].startTime = block.timestamp;

    emit LogStake(msg.sender, _amount);
  }

  function unstake(uint256 _amount) external whenNotPaused nonReentrant {
    require(_amount > 0, "Unstaking amount must be greater than zero");
    require(staker[msg.sender].amount >= _amount, "Insufficient unstake");
    uint256 feeAmount = 0;

    uint256 amountReward = _withdrawRewards();
    staker[msg.sender].amount -= _amount;
    staker[msg.sender].startTime = block.timestamp;
    staker[msg.sender].stakeRewards = 0;
    /**
     * withdraw first and then transfer back the fee 
     */
    depositWallet.withdraw(msg.sender, _amount);

    if (stakeFee >0) {
      feeAmount = _amount * stakeFee / 100;
      require(teletreonToken.transferFrom(msg.sender, feeReceiver, feeAmount), "Transferfrom Failed");
    } 

    emit LogUnstake(msg.sender, _amount, amountReward);
  }

  function fillRewards(uint256 _amount) external whenNotPaused {
    require(address(rewardWallet) != address(0), "Reward Wallet not Set");
    require(_amount > 0, "reward amount must be greater than zero");
    require(teletreonToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    require(teletreonToken.transferFrom(msg.sender, address(rewardWallet), _amount), "TransferFrom fail");

    emit LogFillReward(msg.sender, _amount);
  }

  function _withdrawRewards() internal returns (uint256) {
    uint256 amountWithdraw = getTotalRewards(msg.sender);
    if (amountWithdraw > 0) {
      rewardWallet.withdraw(msg.sender, amountWithdraw);
    }
    return amountWithdraw;
  }

  // function withdrawRewards() external whenNotPaused nonReentrant {
  //   uint256 amountWithdraw = _withdrawRewards();
  //   require(amountWithdraw > 0, "Insufficient rewards balance");
  //   staker[msg.sender].startTime = block.timestamp;
  //   staker[msg.sender].stakeRewards = 0;

  //   emit LogRewardsWithdrawal(msg.sender, amountWithdraw);
  // }

  function getTotalRewards(address _staker) public view returns (uint256) {
    uint256 rateLenght = rate.length;
    uint256 newRewards = 0;

    for (uint256 i = 0; i < rateLenght; i++) {
      if (staker[_staker].startTime > rate[i].startBlock) {
        newRewards = newRewards + ((block.timestamp - staker[_staker].startTime) * staker[_staker].amount * rate[i].apy) /
      (YEAR_SECOND * 100);
      }
    }

    return newRewards + staker[_staker].stakeRewards;
  }

  function calculateRewards(uint256 _start, uint256 _amount) public view returns (uint256) {
    uint256 newRewards = ((block.timestamp - _start) * _amount * rate[rate.length - 1].apy) / (YEAR_SECOND * 100);
    return newRewards;
  }

  function getPendingRewards(address _staker) public view returns (uint256) {
    return staker[_staker].stakeRewards;
  }

  function setPause() external onlyOwner {
    _pause();
  }

  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(teletreonToken), "Cannot be staked token");
    IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

    emit LogTokenRecovery(_tokenAddress, _tokenAmount);
  }

    

  function setUnpause() external onlyOwner {
    _unpause();
  }
}