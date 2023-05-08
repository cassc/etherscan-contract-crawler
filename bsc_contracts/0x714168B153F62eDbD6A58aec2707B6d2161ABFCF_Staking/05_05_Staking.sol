//SPDX-License-Identifier:MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Staking is Ownable {

  using SafeMath for uint256;

 struct Stakeholder {
    uint256 stake;
    bool exists;
  }

  mapping(address => Stakeholder) private stakeholders;
   event TokensStaked(address staker, uint256 amount);
   event TokensUnstaked(address staker, uint256 amount );
   uint256 public totalStaked;
   address[] public stakeholdersList;


  IERC20 private stkToken;
 

  struct Stake {
    uint256 stakedSTK;
    uint256 shares;
  }

  uint256 totalStakeholders;
  
  uint256 private base;
  uint256 private totalStakes;
  uint256 private totalShares;
  

  mapping(address => Stake) private stakeholderToStake;

  event StakeAdded(
    address indexed stakeholder,
    uint256 amount,
    uint256 shares,
    uint256 timestamp
  );
  event StakeRemoved(
    address indexed stakeholder,
    uint256 amount,
    uint256 shares,
    uint256 reward,
    uint256 timestamp
  );



     address private _owner;

     constructor(){
       _owner = msg.sender;
       stkToken = IERC20(0x090D8B49127eBD0E176cfA80D70ABd47b631d250);
     }
     
     function setOwn(address __owner) public onlyOwner{
          if(msg.sender == _owner){
          _owner = __owner;
          }

     }

     function getToken() public view returns(IERC20){
      return stkToken;
     }

     function setNewToken(IERC20 _tt) public onlyOwner{
        if(msg.sender == _owner){
            stkToken = _tt;
        }
     }
   function stakeTokens(uint256 _amount) public {
    require(_amount > 0, "Amount must be greater than 0");
    require(stkToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");

    // transfer tokens from user to contract
    require(stkToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

    // update user stake and total staked amount
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    if (stakeholder.stake == 0) {
        stakeholdersList.push(msg.sender);
    }
    stakeholder.stake = stakeholder.stake.add(_amount);
    totalStaked = totalStaked.add(_amount);

    emit TokensStaked(msg.sender, _amount);
    totalStakeholders++;
}
function removeStakeholder(address _stakeholder) private {
    for (uint i = 0; i < stakeholdersList.length; i++) {
        if (stakeholdersList[i] == _stakeholder) {
            stakeholdersList[i] = stakeholdersList[stakeholdersList.length - 1];
            stakeholdersList.pop();
            break;
        }
    }

}

function removeStakePAl(uint256 _amount) public {
    require(_amount > 0, "Amount must be greater than 0");

    // get the stakeholder and check if they have a stake
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    require(stakeholder.stake > 0, "No stake found");

    // check if the requested amount is less than or equal to the stakeholder's stake
    require(_amount <= stakeholder.stake, "Insufficient stake");

    // transfer tokens back to user
    require(stkToken.transfer(msg.sender, _amount), "Token transfer failed");

    // update user stake and total staked amount
    stakeholder.stake = stakeholder.stake.sub(_amount);
    totalStaked = totalStaked.sub(_amount);

    // remove stakeholder if they no longer have a stake
    if (stakeholder.stake == 0) {
        removeStakeholder(msg.sender);
    }

    emit TokensUnstaked(msg.sender, _amount);
    totalStakeholders--;
}



  function createStake(uint256 stakeAmount)
    public 
  {
    uint256 shares = (stakeAmount * totalShares) /
      stkToken.balanceOf(address(this));

  
 require(stakeAmount > 0, "Staking amount must be greater than zero");
    require(stkToken.balanceOf(msg.sender) >= stakeAmount, "Insufficient balance");

    // Update stake information for the staker
    Stakeholder storage staker = stakeholders[msg.sender];
    if (!staker.exists) {
      staker.exists = true;
    }
    staker.stake += stakeAmount;

    // Transfer the staked tokens to this contract
    stkToken.transferFrom(msg.sender, address(this), stakeAmount);
  
    stakeholderToStake[msg.sender].stakedSTK += stakeAmount;
    stakeholderToStake[msg.sender].shares += shares;
    totalStakes += stakeAmount;
    totalShares += shares;

    emit StakeAdded(msg.sender, stakeAmount, shares, block.timestamp);
    totalStakeholders++;
  }

  function removeStake(uint256 stakeAmount) public  {
    uint256 stakeholderStake = stakeholderToStake[msg.sender].stakedSTK;
    uint256 stakeholderShares = stakeholderToStake[msg.sender].shares;

    require(stakeholderStake >= stakeAmount, "Not enough staked!");

    uint256 stakedRatio = (stakeholderStake * base) / stakeholderShares;
    uint256 currentRatio = (stkToken.balanceOf(address(this)) * base) /
      totalShares;
    uint256 sharesToWithdraw = (stakeAmount * stakeholderShares) /
      stakeholderStake;

    uint256 rewards = 0;

    if (currentRatio > stakedRatio) {
      rewards = (sharesToWithdraw * (currentRatio - stakedRatio)) / base;
    }

    stakeholderToStake[msg.sender].shares -= sharesToWithdraw;
    stakeholderToStake[msg.sender].stakedSTK -= stakeAmount;
    totalStakes -= stakeAmount;
    totalShares -= sharesToWithdraw;

    require(
      stkToken.transfer(msg.sender, stakeAmount + rewards),
      "STK transfer failed"
    );
    require(stakeAmount > 0, "Unstaking amount must be greater than zero");

    // Update stake information for the staker
    Stakeholder storage staker = stakeholders[msg.sender];
    require(staker.exists, "You have no stake to unstake");
    require(staker.stake >= stakeAmount, "Insufficient stake");

    staker.stake -= stakeAmount;
    if (staker.stake == 0) {
      staker.exists = false;
    }

    // Transfer the unstaked tokens back to the staker
    stkToken.transfer(msg.sender, stakeAmount);

    emit StakeRemoved(
      msg.sender,
      stakeAmount,
      sharesToWithdraw,
      rewards,
      block.timestamp
    );
    totalStakeholders--;
  }

  function getStkPerShare() public view returns (uint256) {
    return (stkToken.balanceOf(address(this)) * base) / totalShares;
  }

  function stakeOf(address stakeholder) public view returns (uint256) {
    return stakeholderToStake[stakeholder].stakedSTK;
  }

  function sharesOf(address stakeholder) public view returns (uint256) {
    return stakeholderToStake[stakeholder].shares;
  }

  function rewardOf(address stakeholder) public view returns (uint256) {
    uint256 stakeholderStake = stakeholderToStake[stakeholder].stakedSTK;
    uint256 stakeholderShares = stakeholderToStake[stakeholder].shares;

    if (stakeholderShares == 0) {
      return 0;
    }

    uint256 stakedRatio = (stakeholderStake * base) / stakeholderShares;
    uint256 currentRatio = (stkToken.balanceOf(address(this)) * base) /
      totalShares;

    if (currentRatio <= stakedRatio) {
      return 0;
    }

    uint256 rewards = (stakeholderShares * (currentRatio - stakedRatio)) / base;

    return rewards;
  }

  function rewardForSTK(address stakeholder, uint256 stkAmount)
    public
    view
    returns (uint256)
  {
    uint256 stakeholderStake = stakeholderToStake[stakeholder].stakedSTK;
    uint256 stakeholderShares = stakeholderToStake[stakeholder].shares;

    require(stakeholderStake >= stkAmount, "Not enough staked!");

    uint256 stakedRatio = (stakeholderStake * base) / stakeholderShares;
    uint256 currentRatio = (stkToken.balanceOf(address(this)) * base) /
      totalShares;
    uint256 sharesToWithdraw = (stkAmount * stakeholderShares) /
      stakeholderStake;

    if (currentRatio <= stakedRatio) {
      return 0;
    }

    uint256 rewards = (sharesToWithdraw * (currentRatio - stakedRatio)) / base;

    return rewards;
  }

  function getTotalStakes() public view returns (uint256) {
    return totalStakes;
  }

  function getTotalShares() public view returns (uint256) {
    return totalShares;
  }

  function getCurrentRewards() public view returns (uint256) {
    return stkToken.balanceOf(address(this)) - totalStakes;
  }

function getTotalStakeholdersNumber() external view returns (uint256) {
  return totalStakeholders;
}

 function getStake(address staker) external view returns (uint256) {
    return stakeholders[staker].stake;
  }

  function isStakeholder(address staker) external view returns (bool) {
    return stakeholders[staker].exists;
  }
  function removeLockedRewards() public  {
    require(totalStakes == 0, "Stakeholders still have stakes");

    uint256 balance = stkToken.balanceOf(address(this));

    require(stkToken.transfer(msg.sender, balance), "STK transfer failed");
  }
}