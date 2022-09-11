// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IERC20Mintable.sol";
import "./SafeOwnable.sol";


contract MasterChef is SafeOwnable {
  using SafeERC20 for IERC20Mintable;

  struct UserInfo {
    uint amount;
    uint rewardDebt;
    uint accruedReward;
  }

  //pool info
  uint public lastRewardBlock;
  uint public accRewardPerShare;


  IERC20Mintable public KIKIToken;
  address public stakingContract;
  uint public rewardPerBlock;
  mapping(address => UserInfo) public userInfo;
  uint public lpSupply = 0; 

  event UpdateRewardPerBlock(uint oldRewardPerBlock, uint newRewardPerBlock);
  event Harvest(address harvester, uint amount);

  modifier onlyStakingContract {
    require(msg.sender == stakingContract, "caller is not staking contract");
    _;
  }

  constructor(
    IERC20Mintable _KIKIToken, 
    uint _rewardPerBlock
  ) SafeOwnable(msg.sender)
  public { 
    require(address(_KIKIToken) != address(0), "KIKIToken address can not be zero");
    KIKIToken = _KIKIToken;
    rewardPerBlock = _rewardPerBlock;
  }

  function setStakingContract(address _stakingContract) external onlyOwner {
    require(stakingContract == address(0), "already be set");
    stakingContract = _stakingContract;
  } 

  function updateRewardPerBlock(uint amount) external onlyOwner {
    emit UpdateRewardPerBlock(rewardPerBlock, amount);
    rewardPerBlock = amount;
    updatePool();
  }

  function pendingReward(address _user) external view returns(uint) {
    UserInfo storage user = userInfo[_user];
    uint _accRewardPerShare = accRewardPerShare;
    if (block.number > lastRewardBlock && lpSupply != 0) {
      uint blockDelta = block.number - lastRewardBlock;
      uint reward = blockDelta * rewardPerBlock; 
      _accRewardPerShare += reward * 1e12 / lpSupply;
    }
    uint pending = user.amount * _accRewardPerShare / 1e12 - user.rewardDebt;
    return user.accruedReward + pending;
  }


  function updatePool() public {
    if (block.number <= lastRewardBlock) {
      return;
    }
    if (lpSupply == 0) {
      lastRewardBlock = block.number;
      return;
    }
    uint blockDelta = block.number - lastRewardBlock;
    uint reward = blockDelta * rewardPerBlock;
    KIKIToken.mint(address(this), reward);
    accRewardPerShare += reward * 1e12 / lpSupply;
    lastRewardBlock = block.number;
  }


  function processDeposit(address account, uint _amount) external onlyStakingContract {
    UserInfo storage user = userInfo[account];
    updatePool();
    if (user.amount > 0) {
      uint pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
      user.accruedReward += pending;
    }
    user.amount += _amount;
    user.rewardDebt = user.amount * accRewardPerShare / 1e12;
    lpSupply += _amount;
  }

  function processWithdraw(address account, uint _amount) external onlyStakingContract {
    UserInfo storage user = userInfo[account];
    updatePool();
    uint pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
    user.accruedReward += pending;
    user.amount -= _amount;
    user.rewardDebt = user.amount * accRewardPerShare / 1e12;
    lpSupply -= _amount;
  }

  function harvest() external {
    UserInfo storage user = userInfo[msg.sender];
    if (user.amount == 0 && user.accruedReward == 0) {
      return;
    }
    updatePool();
    uint pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
    user.rewardDebt = user.amount * accRewardPerShare / 1e12;
    uint reward = user.accruedReward + pending;
    user.accruedReward = 0;
    KIKIToken.safeTransfer(msg.sender, reward);
    emit Harvest(msg.sender, reward);
  }
}