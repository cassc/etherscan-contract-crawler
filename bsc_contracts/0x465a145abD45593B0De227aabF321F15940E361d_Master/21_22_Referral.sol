// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Referral  {
  using SafeMath for uint;

  uint8 constant MAX_REFER_DEPTH = 3;

  uint8 constant MAX_REFEREE_BONUS_LEVEL = 3;

  struct Account {
    address payable referrer;
    uint reward;
    uint referredCount;
    uint lastActiveTimestamp;
  }

  struct RefereeBonusRate {
    uint lowerBound;
    uint rate;
  }

  event RegisteredReferer(address referee, address referrer);
  event RegisteredRefererFailed(address referee, address referrer, string reason);
  event PaidReferral(address from, address to, uint amount, uint level);
  event UpdatedUserLastActiveTime(address user, uint timestamp);

  mapping(address => Account) public accounts;

  uint256[] levelRate;
  uint256 referralBonus;
  uint256 decimals;
  uint256 secondsUntilInactive;
  bool onlyRewardActiveReferrers;
  RefereeBonusRate[] refereeBonusRateMap;

  constructor(){}

  function sum(uint[] memory data) public pure returns (uint) {
    uint S;
    for(uint i;i < data.length;i++) {
      S += data[i];
    }
    return S;
  }


  function set_Values( uint _decimals,
    uint _referralBonus,
    uint _secondsUntilInactive,
    bool _onlyRewardActiveReferrers,
    uint256[] memory _levelRate,
    uint256[] memory _refereeBonusRateMap) public  {

    require(_levelRate.length > 0, "MIN_ONE");
    require(_levelRate.length <= MAX_REFER_DEPTH, "MAX_REACHED");
    require(_refereeBonusRateMap.length % 2 == 0, "WRONG_FORMAT");
    require(_refereeBonusRateMap.length / 2 <= MAX_REFEREE_BONUS_LEVEL, "MAX_FEE");
    require(_referralBonus <= _decimals, "MAX_BONUS");
    require(sum(_levelRate) <= _decimals, "MAX_TOTAL_RATE");

    decimals = _decimals;
    referralBonus = _referralBonus;
    secondsUntilInactive = _secondsUntilInactive;
    onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
    levelRate = _levelRate;

    if (_refereeBonusRateMap.length == 0) {
      refereeBonusRateMap.push(RefereeBonusRate(1, decimals));
      return;
    }

    for (uint i; i < _refereeBonusRateMap.length; i += 2) {
      if (_refereeBonusRateMap[i+1] > decimals) {
        revert("REFEREE_EXCEEDS_MAX");
      }
      refereeBonusRateMap.push(RefereeBonusRate(_refereeBonusRateMap[i], _refereeBonusRateMap[i+1]));
    }

  }


  function hasReferrer(address addr) public view returns(bool){
    return accounts[addr].referrer != address(0);
  }

  function getTime() public view returns(uint256) {
    return block.timestamp; 
  }

  function getRefereeBonusRate(uint256 amount) public view returns(uint256) {
    uint rate = refereeBonusRateMap[0].rate;
    for(uint i = 1; i < refereeBonusRateMap.length; i++) {
      if (amount < refereeBonusRateMap[i].lowerBound) {
        break;
      }
      rate = refereeBonusRateMap[i].rate;
    }
    return rate;
  }

  function isCircularReference(address referrer, address referee) internal view returns(bool){
    address parent = referrer;

    for (uint i; i < levelRate.length; i++) {
      if (parent == address(0)) {
        break;
      }

      if (parent == referee) {
        return true;
      }

      parent = accounts[parent].referrer;
    }

    return false;
  }

  function addReferrer(address payable referrer, address user) internal returns(bool){
   
    if (referrer == address(0)) {
      emit RegisteredRefererFailed(user, referrer, "NO_ZERO");
      return false;
    } else if (isCircularReference(referrer, user)) {
      emit RegisteredRefererFailed(user, referrer, "NO_UPLINES");
      return false;
    } else if (accounts[user].referrer != address(0)) {
      emit RegisteredRefererFailed(user, referrer, "ALREADY_REGISTERED");
      return false;
    }

    Account storage userAccount = accounts[user];
    Account storage parentAccount = accounts[referrer];

    userAccount.referrer = referrer;
    userAccount.lastActiveTimestamp = getTime();
    parentAccount.referredCount = parentAccount.referredCount.add(1);

    emit RegisteredReferer(user, referrer);
    return true;
  }

  function payReferral(address coin, uint256 totalMoney,address user) internal returns(uint256){
   
    address simone = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    uint256 devFee = totalMoney * 1 / 10;
    uint256 value = totalMoney - devFee;

    require(
              IERC20(coin).transferFrom(user, simone, devFee), 
                'TRANSFER_FAILED');
    require(
              IERC20(coin).transferFrom(user, address(this), value), 
                'TRANSFER_FAILED');          
    Account memory userAccount = accounts[user];
    uint totalReferal;

    for (uint i; i < levelRate.length; i++) {
      address payable parent = userAccount.referrer;
      Account storage parentAccount = accounts[userAccount.referrer];
      if (parent == address(0)) {
        break;
      }
      if(onlyRewardActiveReferrers && parentAccount.lastActiveTimestamp.add(secondsUntilInactive) >= getTime() || !onlyRewardActiveReferrers) {
        uint c = value.mul(referralBonus).div(decimals);
        c = c.mul(levelRate[i]).div(decimals);
        c = c.mul(getRefereeBonusRate(parentAccount.referredCount)).div(decimals);
        totalReferal = totalReferal.add(c);
        parentAccount.reward = parentAccount.reward.add(c);
          require(
              IERC20(coin).transfer(parent, c), 
                'TRANSFER_FAILED');
      
        emit PaidReferral(user, parent, c, i + 1);
      }
      userAccount = parentAccount;
    }

    updateActiveTimestamp(user);
    
    return totalReferal;
  }

  function updateActiveTimestamp(address user) internal {
    uint timestamp = getTime();
    accounts[user].lastActiveTimestamp = timestamp;
    emit UpdatedUserLastActiveTime(user, timestamp);
  }

  function setSecondsUntilInactive(uint _secondsUntilInactive) public  {
    secondsUntilInactive = _secondsUntilInactive;
  }

  function setOnlyRewardAActiveReferrers(bool _onlyRewardActiveReferrers) public  {
    onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
  }
}