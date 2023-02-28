// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Users.sol";
import "./Math.sol";

contract NewPool is Users {
  using Math for uint256;
  using Math for uint64;

  constructor(address admin) Secure(admin) {}

  modifier hasEnoughInvest() {
    require(_totalInvest(_msgSender()) >= INVEST_STEPS[0], "INE");
    _;
  }

  receive() external payable {
    stake(ADMIN, false);
  }

  // Price Calculation view Functions
  function BNBPrice() public view override returns (uint256) {
    int256 price = BNB_USD.latestAnswer();

    return uint256(price);
  }

  function TokenPrice() public view override returns (uint256) {
    (uint256 res0, uint256 res1, ) = TOKEN_PAIR.getReserves();

    return res1.mulDecimals(8).div(res0);
  }

  function BNBValue(address user) external view override returns (uint256) {
    return user.balance;
  }

  function TokenValue(address user) external view override returns (uint256) {
    return _TokenBalance(user);
  }

  function BNBtoUSD(uint256 value) public view override returns (uint256) {
    return value.mul(BNBPrice()).divDecimals(18);
  }

  function TokenToUSD(uint256 value) public view override returns (uint256) {
    return value.mul(TokenPrice()).divDecimals(18);
  }

  function USDtoBNB(uint256 value) public view override returns (uint256) {
    return value.mulDecimals(18).div(BNBPrice());
  }

  function USDtoToken(uint256 value) public view override returns (uint256) {
    return value.mulDecimals(18).div(TokenPrice());
  }

  // User Interact Deposit functions
  function stake(address referrer, bool isMonthly) public payable override {
    uint256 value = BNBtoUSD(msg.value);
    require(value >= INVEST_STEPS[0], "VAL");

    UserStruct storage user = users[_msgSender()];

    uint64 hourly = calculateHourlyReward(value, isMonthly);

    if (user.referrer == address(0)) {
      require(_totalInvest(referrer) >= INVEST_STEPS[0], "REF");

      user.referrer = referrer;
      user.percent = PERCENT_STEPS[0];
      user.isTokenMode = users[referrer].isTokenMode;

      _afterDeposit(user, value, hourly);

      emit RegisterUser(_msgSender(), referrer, value, hourly);
    } else {
      _afterDeposit(user, value, hourly);

      emit UpdateUser(_msgSender(), user.referrer, value, hourly);
    }

    users[ADMIN].invest.push(Invest(value.toUint64(), 0, block.timestamp.toUint64(), 0));
  }

  function stakeToken(address referrer, uint256 amount) public override {
    uint256 value = TokenToUSD(amount);
    require(value >= INVEST_STEPS[0], "VAL");

    _safeDepositToken(_msgSender(), amount);

    UserStruct storage user = users[_msgSender()];

    if (user.referrer == address(0)) {
      require(users[referrer].isTokenMode, "RNT");
      require(_totalInvest(referrer) >= INVEST_STEPS[0], "REF");

      user.referrer = referrer;
      user.percent = PERCENT_STEPS[0];
      user.isTokenMode = true;

      _afterDeposit(user, value, 0);

      emit RegisterUserToken(_msgSender(), referrer, value);
    } else {
      require(user.isTokenMode, "NOT");

      _afterDeposit(user, value, 0);

      emit UpdateUserToken(_msgSender(), user.referrer, value);
    }
  }

  // User Interact Withdraw functions
  function withdrawToInvest(bool isMonthly) external override hasEnoughInvest {
    UserStruct storage user = users[_msgSender()];

    require(!user.isBlackListed, "BLK");

    uint256 interest = _updateBeforWithdrawInterest(user);

    uint256 totalAmount = interest.add(user.refReward);

    require(totalAmount >= INVEST_STEPS[0], "VAL");

    user.refReward = 0;

    uint64 hourly = calculateHourlyReward(totalAmount, isMonthly);

    _afterDeposit(user, totalAmount, hourly);

    emit WithdrawToInvest(_msgSender(), user.referrer, totalAmount, hourly);
  }

  function withdrawInterest() public override secured hasEnoughInvest {
    UserStruct storage user = users[_msgSender()];

    require(!user.isBlackListed, "BLK");

    uint256 interest = _updateBeforWithdrawInterest(user);

    uint256 refReward = user.refReward;

    uint256 totalReward = interest.add(refReward);

    _safeWithdraw(_msgSender(), totalReward, user.isTokenMode || TOKEN_MODE);

    user.refReward = 0;

    emit WithdrawInterest(_msgSender(), interest, refReward);
  }

  function withdrawIndexInterest(uint256 index) public secured hasEnoughInvest {
    UserStruct storage user = users[_msgSender()];

    require(!user.isBlackListed, "BLK");

    uint256 requestTime = block.timestamp;

    Invest storage userIvest = user.invest[index];

    (uint256 interest, ) = _indexInterest(userIvest, user.percent, requestTime);

    _safeWithdraw(_msgSender(), interest, user.isTokenMode || TOKEN_MODE);

    userIvest.latestWithdraw = requestTime.toUint64();

    emit WithdrawIndexInterest(_msgSender(), index, interest);
  }

  function withdrawInvest(uint256 index)
    external
    override
    secured
    notInterestMode
    hasEnoughInvest
  {
    UserStruct storage user = users[_msgSender()];

    require(!user.isBlackListed, "BLK");
    require(!user.isInterestMode, "INT");

    uint256 requestTime = block.timestamp;

    Invest storage userIvest = user.invest[index];

    (uint256 interest, ) = _indexInterest(userIvest, user.percent, requestTime);

    uint256 amount = _updateBeforeWithdrawInvest(userIvest, user.referrer);

    uint256 total = amount.add(interest);

    _safeWithdraw(_msgSender(), total, user.isTokenMode || TOKEN_MODE);

    userIvest.latestWithdraw = requestTime.toUint64();

    if (interest > 0) {
      emit WithdrawIndexInterest(_msgSender(), index, interest);
    }
    emit WithdrawInvest(_msgSender(), user.referrer, amount);
  }

  // User Interact Switch Funtions
  function intoMonthlyInvest(uint256 index) external override hasEnoughInvest {
    Invest storage invest = users[_msgSender()].invest[index];

    require(invest.startTime != 0, "INW");

    invest.hourly = calculateHourlyReward(invest.amount, true);
    invest.startTime = block.timestamp.toUint64();
  }

  function intoTokenMode() external payable override hasEnoughInvest {
    require(msg.value >= TOKEN_MODE_FEE, "VAL");

    users[_msgSender()].isTokenMode = true;
  }

  // Internal functions
  function _safeWithdraw(
    address to,
    uint256 usdAmount,
    bool isToken
  ) private {
    require(usdAmount > 0, "NTW");

    if (isToken) {
      _safeTransferToken(to, USDtoToken(usdAmount));
    } else {
      _safeTransferBNB(to, USDtoBNB(usdAmount.sub(FEE)));
    }
  }

  function _afterDeposit(
    UserStruct storage user,
    uint256 value,
    uint64 hourly
  ) private {
    user.invest.push(Invest(value.toUint64(), hourly, block.timestamp.toUint64(), 0));

    UserStruct storage referrer = users[user.referrer];

    referrer.levelOneTotal = referrer.levelOneTotal.add(value);

    if (hourly > 0) {
      uint256 refReward = value.mul(REF_REWARD_PERCENT).div(HUNDRED_PERCENT);
      referrer.refReward = referrer.refReward.add(refReward).toUint64();
      emit RewardRecieved(user.referrer, refReward);
    }
  }

  function _updateBeforeWithdrawInvest(Invest storage invest, address refAddress)
    private
    returns (uint256 value)
  {
    require(invest.startTime != 0, "INW");

    if (invest.hourly > 0) {
      uint256 endTime = invest.startTime.add(MONTHLY_TIME);
      require(block.timestamp >= endTime, "INN");
    }

    invest.startTime = 0;

    value = invest.amount;

    UserStruct storage referrer = users[refAddress];

    if (referrer.levelOneTotal >= value) {
      referrer.levelOneTotal = referrer.levelOneTotal.sub(value);

      _updateByReferral(referrer);
    }
  }

  function _updateBeforWithdrawInterest(UserStruct storage user)
    private
    returns (uint256 rewards)
  {
    uint256 totalTimePassed;

    uint256 userPercent = user.percent;

    uint256 requestTime = block.timestamp;

    Invest[] storage userIvests = user.invest;

    for (uint8 i = 0; i < userIvests.length; i++) {
      Invest storage userIvest = userIvests[i];

      (uint256 interest, uint256 timePassed) = _indexInterest(
        userIvest,
        userPercent,
        requestTime
      );

      if (interest > 0) {
        userIvest.latestWithdraw = requestTime.toUint64();
        emit WithdrawIndexInterest(_msgSender(), i, interest);
      }

      totalTimePassed = totalTimePassed.add(timePassed);

      rewards = rewards.add(interest);
    }

    if (totalTimePassed.toDays() > 0) {
      _updateByUser(user);
    }
  }

  function _indexInterest(
    Invest storage userIvest,
    uint256 userPercent,
    uint256 requestTime
  ) private view returns (uint256 interest, uint256 timePassed) {
    uint256 startTime = userIvest.startTime;
    if (startTime == 0) return (0, 0);

    uint256 latestWithdraw = userIvest.latestWithdraw;

    if (latestWithdraw > startTime) {
      timePassed = requestTime.sub(latestWithdraw);
    } else {
      timePassed = requestTime.sub(startTime);
    }

    uint256 hourlyReward = userIvest.hourly;

    if (hourlyReward > 0) {
      uint256 hourPassed = timePassed.toHours();

      if (hourPassed > 0) {
        interest = hourPassed.mul(hourlyReward);
      }
    } else {
      uint256 dayPassed = timePassed.toDays();

      if (dayPassed > 0) {
        uint256 dailyReward = userIvest.amount.mul(userPercent).div(HUNDRED_PERCENT);

        interest = dayPassed.mul(dailyReward);
      }
    }
  }

  function _updateByUser(UserStruct storage user) private {
    uint256 levelOneTotal = user.levelOneTotal;

    if (user.percent == 0) return;

    if (levelOneTotal >= INVEST_STEPS[3]) {
      user.percent = PERCENT_STEPS[3];
    } else if (levelOneTotal >= INVEST_STEPS[2]) {
      user.percent = PERCENT_STEPS[2];
    } else if (levelOneTotal >= INVEST_STEPS[1]) {
      user.percent = PERCENT_STEPS[1];
    } else {
      user.percent = PERCENT_STEPS[0];
    }
  }

  function _updateByReferral(UserStruct storage referrer) private {
    uint256 levelOneTotal = referrer.levelOneTotal;
    uint8 percent = referrer.percent;

    if (percent == 0) return;

    if (percent == PERCENT_STEPS[3] && levelOneTotal < INVEST_STEPS[3]) {
      referrer.percent = PERCENT_STEPS[2];
    } else if (percent == PERCENT_STEPS[2] && levelOneTotal < INVEST_STEPS[2]) {
      referrer.percent = PERCENT_STEPS[1];
    } else if (percent == PERCENT_STEPS[1] && levelOneTotal < INVEST_STEPS[1]) {
      referrer.percent = PERCENT_STEPS[0];
    }
  }

  function _totalInvest(address user) private view returns (uint256 totalAmount) {
    Invest[] storage userIvests = users[user].invest;
    for (uint8 i = 0; i < userIvests.length; i++) {
      Invest storage userIvest = userIvests[i];
      if (userIvest.startTime != 0) totalAmount = totalAmount.add(userIvest.amount);
    }
  }

  // Calculate view function
  function calculateHourlyReward(uint256 value, bool isMonthly)
    public
    view
    returns (uint64)
  {
    if (!isMonthly) return 0;
    return value.mul(MONTHLY_PERCENT).div(HUNDRED_PERCENT).div(MONTHLY_HOURS).toUint64();
  }

  // User API Functions
  function userDepositNumber(address user) external view override returns (uint256) {
    return users[user].invest.length;
  }

  function userDepositDetails(address user, uint256 index)
    external
    view
    override
    returns (Invest memory)
  {
    return users[user].invest[index];
  }

  function userInvestDetails(address user)
    external
    view
    override
    returns (Invest[] memory invest, uint256 total)
  {
    invest = users[user].invest;

    for (uint8 i = 0; i < invest.length; i++) {
      Invest memory userIvest = invest[i];
      if (userIvest.startTime != 0) total = total.add(userIvest.amount);
    }
  }

  function userInterestDetails(address sender, uint256 requestTime)
    public
    view
    override
    returns (Interest[] memory interest, uint256 total)
  {
    if (requestTime == 0) requestTime = block.timestamp;

    interest = new Interest[](users[sender].invest.length);

    UserStruct storage user = users[sender];

    uint256 userPercent = user.percent;

    for (uint8 i = 0; i < interest.length; i++) {
      Invest storage invest = user.invest[i];
      (uint256 amount, uint256 passedTime) = _indexInterest(
        invest,
        userPercent,
        requestTime
      );

      interest[i].amount = amount;
      interest[i].time = passedTime;

      total = total.add(amount);
    }
  }

  // Admin API Functions
  function updateUserPercent(address user) external onlyOwnerOrAdmin {
    _updateByUser(users[user]);
  }

  function addMonth(address user, uint256 index) external onlyOwnerOrAdmin {
    Invest storage invest = users[user].invest[index];

    invest.startTime = uint64(block.timestamp);

    if (invest.hourly == 0) {
      invest.hourly = calculateHourlyReward(invest.amount, true);
    }
  }
}