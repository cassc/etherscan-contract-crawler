// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WhitelistStacks is Ownable {
  ERC20 public usdcAddress;
  bool public openWithdrawals;
  bool public contractActive;

  uint public DECIMALS = 10**6;

  uint [] public plans = [
    100 * DECIMALS,
    250 * DECIMALS,
    500 * DECIMALS,
    1000 * DECIMALS
  ];

  struct Account {
    address accountAddress;
    address referredBy;
    uint amountPaid;
    bool exists;
  }

  mapping(address => Account) public whitelist;
  address [] public whitelistArr; // for key identification
  mapping(address => uint) public referralsLength;
  uint public totalReferralCount;
  uint public whitelistLength;
  uint public maxListLength = 1000;

  event WhitelistAdded(address indexed account);
  event ReferralFeesPaid(address indexed account);

  constructor(address _usdcAddress) {
    usdcAddress = ERC20(_usdcAddress);
  }

  // make payment and add sender address to whitelist with according plan
  function addToWhitelist(address _referredBy) public {
    require(contractActive, "Contract is not active");
    require(whitelistLength < maxListLength, "Sorry, whitelist is full");
    require(!whitelist[msg.sender].exists, "Address already registered for whitelist");
    require(_referredBy != msg.sender, "You cannot refer yourself");

    // filter out referral if not registered
    address referredBy;
    if(whitelist[_referredBy].exists) {
      referredBy = _referredBy;
      totalReferralCount++;
    }
    else {
      referredBy = address(0);
    }

    uint plan = currentPlan();
    usdcAddress.transferFrom(msg.sender, address(this), plans[plan]);
    addUserToList(msg.sender, referredBy, plans[plan], true);
  }

  function receiveReferral() public {
    require(openWithdrawals, "Fund withdrawals are closed");
    require(referralsLength[msg.sender] > 0, "No referrals found");

    uint amount = amountToPayToReferrer(msg.sender);
    referralsLength[msg.sender] = 0;
    totalReferralCount -= referralsLength[msg.sender];
    usdcAddress.transfer(msg.sender, amount);
    emit ReferralFeesPaid(msg.sender);
  }

  function currentPlan() public view returns(uint) {
    if(whitelistLength < 100) {
      return 0;
    } else if(whitelistLength < 250) {
      return 1;
    } else if(whitelistLength < 500) {
      return 2;
    } else {
      return 3;
    }
  }

  function amountToPayToReferrer(address _user) public view returns(uint) {
    return referralsLength[_user] * 50 * DECIMALS;
  }

  // Admin functions
  function setOpenWithdrawals(bool _openWithdrawals) public onlyOwner {
    openWithdrawals = _openWithdrawals;
  }

  function withdrawFunds(address to, uint amount) public onlyOwner {
    usdcAddress.transfer(to, amount);
  }

  function setMaxListLength(uint _maxListLength) public onlyOwner {
    maxListLength = _maxListLength;
  }

  function setContractActive(bool _value) public onlyOwner {
    contractActive = _value;
  }

  function addToWhitelistAdmin(address _user) public onlyOwner {
    require(!whitelist[_user].exists, "Address already registered for whitelist");
    addUserToList(_user, address(0), 0, false);
  }

  function removeUserFromWhitelist(address _user, bool decrementLength) public onlyOwner {
    require(whitelist[_user].exists, "Address not registered for whitelist");
    whitelist[_user].exists = false;
    if(decrementLength) { whitelistLength--; }
  }

  function totalLeftToPayReferrals() public view returns(uint) {
    return totalReferralCount * 50 * DECIMALS;
  }

  function addUserToList(address _user, address _referredBy, uint _amountPaid, bool increment) private {
    whitelist[_user] = Account({
      accountAddress: _user,
      referredBy: _referredBy,
      amountPaid: _amountPaid,
      exists: true
    });
    whitelistArr.push(_user);
    if(increment) { whitelistLength++; }
    referralsLength[_referredBy]++;
    emit WhitelistAdded(_user);
  }
}