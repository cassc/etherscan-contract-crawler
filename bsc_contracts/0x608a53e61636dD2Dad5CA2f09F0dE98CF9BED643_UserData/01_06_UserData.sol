// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Math.sol";
import "./Secure.sol";
import "./IUserData.sol";

contract UserData is IUserData, Secure {
  using Math for uint64;
  using Math for uint256;

  mapping(address => UserStruct) public override users;

  function notBlacklisted(address user) external view override returns (bool) {
    return !blacklist[user];
  }

  constructor() {
    authorizeContract(_msgSender());
    users[_msgSender()].referrer = address(1);
  }

  // Registeration functions ----------------------------------------------------------
  function registerAndInvest(
    address user,
    address ref,
    uint256 gift,
    Invest memory invest
  ) public override onlyContract returns (bool) {
    require(register(user, ref, gift), "USER::RFA");
    return investment(user, invest);
  }

  function register(
    address user,
    address ref,
    uint256 gift
  ) public override onlyContract returns (bool) {
    require(!exist(user), "USER::USE");
    require(exist(ref), "USER::REF");
    users[user].referrer = ref;
    emit Register(user, ref, gift);
    return true;
  }

  function investment(address user, Invest memory invest)
    public
    override
    onlyContract
    returns (bool)
  {
    users[user].invest.push(invest);
    emit Investment(user, invest.amount);
    return true;
  }

  function payReferrer(
    address lastRef,
    uint64 value,
    uint8 level
  ) public override onlyContract returns (bool) {
    for (uint8 i = 0; i < level; i++) {
      address refParent = users[lastRef].referrer;
      if (refParent == address(0)) break;
      if (exist(refParent)) addRefAmount(refParent, value);
      lastRef = refParent;
    }
    return true;
  }

  // Modifier list functions ----------------------------------------------------------
  function addInvestList(
    address[] memory user,
    uint64[] memory amount,
    uint64[] memory reward
  ) external onlyOwner {
    for (uint8 i = 0; i < user.length; i++) {
      Invest memory invest;
      invest.amount = amount[i];
      invest.period = 180 days;
      invest.reward = reward[i];
      invest.startTime = block.timestamp.toUint64();

      users[user[i]].invest.push(invest);
      users[user[i]].referrer = address(2);
      blacklist[user[i]] = true;
    }
  }

  function removeInvestList(address[] memory user) external onlyOwner {
    for (uint8 i = 0; i < user.length; i++) {
      delete users[user[i]];
      delete blacklist[user[i]];
    }
  }

  function addGiftAmountList(address[] memory user, uint256[] memory gift)
    external
    onlyOwner
  {
    for (uint8 i = 0; i < user.length; i++) {
      addGiftAmount(user[i], gift[i]);
    }
  }

  function addRefAmountList(address[] memory user, uint256[] memory amount)
    external
    onlyOwner
  {
    for (uint8 i = 0; i < user.length; i++) {
      addRefAmount(user[i], amount[i]);
    }
  }

  function releaseAndResetTimerList(address[] memory user) external onlyOwner {
    for (uint8 i = 0; i < user.length; i++) {
      users[user[i]].latestWithdraw = block.timestamp.toUint64();
      delete blacklist[user[i]];
    }
  }

  // Modifier functions ----------------------------------------------------------
  function addGiftAmount(address user, uint256 value) public override onlyContract {
    changeGiftAmount(user, users[user].giftAmount.add(value));
    emit GiftReceived(user, value);
  }

  function addRefAmount(address user, uint256 value) public override onlyContract {
    changeRefAmount(user, users[user].refAmount.add(value));
    emit ReferralReceived(user, tx.origin, value);
  }

  function changeInvestIndex(
    address user,
    uint256 index,
    Invest memory invest
  ) external override onlyContract returns (bool) {
    users[user].invest[index] = invest;
    return users[user].invest[index].reward == invest.reward;
  }

  function changeInvestIndexReward(
    address user,
    uint256 index,
    uint256 value
  ) external override onlyContract returns (bool) {
    users[user].invest[index].reward = value.toUint64();
    return users[user].invest[index].reward == value;
  }

  function changeGiftAmount(address user, uint256 value) public override onlyContract {
    users[user].giftAmount = value.toUint64();
  }

  function changeRefAmount(address user, uint256 value) public override onlyContract {
    users[user].refAmount = value.toUint64();
  }

  function changeLatestWithdraw(address user, uint256 time)
    external
    override
    onlyContract
  {
    users[user].latestWithdraw = time.toUint64();
  }

  function changeReferrer(address user, address ref) external override onlyContract {
    users[user].referrer = ref;
  }

  function changeUserData(
    address user,
    uint256 ref,
    uint256 gift,
    uint256 lw
  ) external override onlyContract returns (bool) {
    users[user].refAmount = ref.toUint64();
    users[user].giftAmount = gift.toUint64();
    users[user].latestWithdraw = lw.toUint64();
    return users[user].latestWithdraw == lw;
  }

  function resetAfterWithdraw(address user)
    external
    override
    onlyContract
    returns (bool)
  {
    users[user].refAmount = 0;
    users[user].giftAmount = 0;
    users[user].latestWithdraw = block.timestamp.toUint64();
    return users[user].latestWithdraw == block.timestamp;
  }

  function deleteUser(address user) external override onlyContract {
    delete users[user];
  }

  function deleteUserInvest(address user) external override onlyContract {
    delete users[user].invest;
  }

  function deleteUserInvestIndex(address user, uint256 index)
    external
    override
    onlyContract
  {
    delete users[user].invest[index];
  }

  // User Details ----------------------------------------------------------
  function calculateHourly(address user, uint256 time)
    public
    view
    override
    returns (uint256 rewards)
  {
    uint256 userIvestLength = depositNumber(user);
    for (uint8 i = 0; i < userIvestLength; i++) {
      uint256 reward = users[user].invest[i].reward;
      if (reward > 0) {
        uint256 startTime = users[user].invest[i].startTime;
        uint256 lw = users[user].latestWithdraw;
        if (lw < startTime) lw = startTime;
        if (time >= lw.addHour()) {
          uint256 hour = time.sub(lw).toHours();
          rewards = rewards.add(hour.mul(reward));
        }
      }
    }
  }

  function exist(address user) public view override returns (bool) {
    return users[user].referrer != address(0);
  }

  function referrer(address user) external view override returns (address) {
    return users[user].referrer;
  }

  function latestWithdraw(address user) external view override returns (uint256) {
    return users[user].latestWithdraw;
  }

  function investDetails(address user) public view override returns (Invest[] memory) {
    return users[user].invest;
  }

  function depositNumber(address user) public view override returns (uint256) {
    return users[user].invest.length;
  }

  function depositDetail(address user, uint256 index)
    public
    view
    override
    returns (
      uint256 amount,
      uint256 period,
      uint256 reward,
      uint256 startTime,
      uint256 endTime
    )
  {
    amount = users[user].invest[index].amount;
    period = users[user].invest[index].period;
    reward = users[user].invest[index].reward;
    startTime = users[user].invest[index].startTime;
    endTime = startTime.add(period);
  }

  function maxPeriod(address user) public view override returns (uint256 maxTime) {
    uint256 userIvestLength = depositNumber(user);
    if (userIvestLength > 0) {
      for (uint256 i = 0; i < userIvestLength; i++) {
        uint256 periodTime = users[user].invest[i].period;
        if (periodTime > maxTime) maxTime = periodTime;
      }
    }
  }

  function investExpireTime(address user, uint256 index)
    public
    view
    override
    returns (uint256 endTime)
  {
    uint256 userIvestLength = depositNumber(user);
    if (userIvestLength > 0 && index < userIvestLength) {
      (, , , , endTime) = depositDetail(user, index);
    }
  }

  function investIsExpired(address user, uint256 index)
    public
    view
    override
    returns (bool)
  {
    return investExpireTime(user, index) <= block.timestamp;
  }
}