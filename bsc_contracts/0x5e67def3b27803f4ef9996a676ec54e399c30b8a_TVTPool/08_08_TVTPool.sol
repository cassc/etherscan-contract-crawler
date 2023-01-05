// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Migration.sol";

contract TVTPool is Migration {
  using Math for uint256;

  constructor() {
    owner = _msgSender();
  }

  receive() external payable {
    mining(owner);
  }

  // Price Calculation
  function BNBPrice() public view override returns (uint256) {
    int256 price = BNB_USD.latestAnswer();

    return uint256(price);
  }

  function TVTPrice() public view override returns (uint256) {
    (uint res0, uint res1, ) = TVT_USD.getReserves();

    return res1.mulDecimals(8).div(res0);
  }

  function BNBtoUSD(uint256 value) public view override returns (uint256) {
    return value.mul(BNBPrice()).divDecimals(18);
  }

  function TVTtoUSD(uint256 value) public view override returns (uint256) {
    return value.mul(TVTPrice()).divDecimals(18);
  }

  function USDtoBNB(uint256 value) public view override returns (uint256) {
    return value.mulDecimals(18).div(BNBPrice());
  }

  function USDtoTVT(uint256 value) public view override returns (uint256) {
    return value.mulDecimals(18).div(TVTPrice());
  }

  // Deposit function
  function mining(address referrer) public payable override {
    uint256 value = BNBtoUSD(msg.value);
    require(value >= MINIMUM_INVEST, "VAL");

    if (users[_msgSender()].referrer == address(0)) {
      require(userTotalInvest(referrer) >= MINIMUM_INVEST, "REF");

      users[_msgSender()].referrer = referrer;
      users[_msgSender()].percent = BASE_PERCENT;
      users[_msgSender()].latestWithdraw = block.timestamp;

      tvtUsers[_msgSender()] = tvtUsers[referrer];

      _deposit(_msgSender(), value);

      emit RegisterUser(_msgSender(), referrer, value);
    } else {
      require(users[_msgSender()].percent > 0, "UIW");

      _deposit(_msgSender(), value);

      emit UpdateUser(_msgSender(), users[_msgSender()].referrer, value);
    }
  }

  function miningTVT(uint amount, address referrer) public override {
    uint256 value = TVTtoUSD(amount);
    require(value >= MINIMUM_INVEST, "VAL");
    require(TVTValue(_msgSender()) >= amount, "TVL");

    _safeDepositTVT(amount);

    if (users[_msgSender()].referrer == address(0)) {
      require(tvtUsers[referrer], "RNT");
      require(userTotalInvest(referrer) >= MINIMUM_INVEST, "REF");

      users[_msgSender()].referrer = referrer;
      users[_msgSender()].percent = BASE_PERCENT;
      users[_msgSender()].latestWithdraw = block.timestamp;

      tvtUsers[_msgSender()] = true;

      _deposit(_msgSender(), value);
      emit RegisterUserTVT(_msgSender(), referrer, value);
    } else {
      require(users[_msgSender()].percent > 0, "UIW");
      require(tvtUsers[_msgSender()], "NOT");

      _deposit(_msgSender(), value);

      emit UpdateUserTVT(_msgSender(), users[_msgSender()].referrer, value);
    }
  }

  // calculate rewards
  function totalInterest(address sender) public view override returns (uint256 rewards) {
    uint256 userPercent = users[sender].percent;

    Invest[] storage userIvest = users[sender].invest;

    for (uint8 i = 0; i < userIvest.length; i++) {
      uint256 startTime = userIvest[i].startTime;
      if (startTime == 0) continue;
      uint256 latestWithdraw = users[sender].latestWithdraw;

      if (latestWithdraw.addDay() <= block.timestamp) {
        if (startTime > latestWithdraw) latestWithdraw = startTime;
        uint256 reward = userPercent.mul(userIvest[i].amount).div(1000);
        uint256 day = block.timestamp.sub(latestWithdraw).toDays();
        rewards = rewards.add(day.mul(reward));
      }
    }
  }

  function calculateInterest(
    address sender
  ) public view override returns (uint256[2][] memory rewards, uint256 requestTime) {
    rewards = new uint256[2][](users[sender].invest.length);
    requestTime = block.timestamp;

    for (uint8 i = 0; i < rewards.length; i++) {
      (uint256 day, uint256 interest) = indexInterest(sender, i);
      rewards[i][0] = day;
      rewards[i][1] = interest;
    }
  }

  function indexInterest(
    address sender,
    uint256 index
  ) public view override returns (uint256 day, uint256 interest) {
    uint256 userPercent = users[sender].percent;
    uint256 latestWithdraw = users[sender].latestWithdraw;

    Invest storage userIvest = users[sender].invest[index];
    uint256 startTime = userIvest.startTime;
    if (startTime == 0) return (0, 0);

    if (latestWithdraw.addDay() <= block.timestamp) {
      if (startTime > latestWithdraw) latestWithdraw = startTime;
      uint256 reward = userPercent.mul(userIvest.amount).div(1000);
      day = block.timestamp.sub(latestWithdraw).toDays();
      interest = day.mul(reward);
    }
  }

  // Widthraw Funtions
  function withdrawToInvest() external override {
    uint256 daily = totalInterest(_msgSender());

    require(daily >= MINIMUM_INVEST, "VAL");

    users[_msgSender()].latestWithdraw = block.timestamp;

    _deposit(_msgSender(), daily);

    emit WithdrawToInvest(_msgSender(), users[_msgSender()].referrer, daily);
  }

  function withdrawInterest() public override secured {
    require(userTotalInvest(_msgSender()) >= MINIMUM_INVEST, "USR");
    uint256 daily = totalInterest(_msgSender());

    require(daily > 0, "VAL");

    users[_msgSender()].latestWithdraw = block.timestamp;

    if (tvtUsers[_msgSender()]) {
      _safeTransferTVT(_msgSender(), USDtoTVT(USDtoTVT(daily))); // Transfer TVT to user
    } else {
      _safeTransferBNB(_msgSender(), USDtoBNB(USDtoBNB(daily.sub(FEE)))); // Transfer BNB to user
    }

    emit WithdrawInterest(_msgSender(), daily);
  }

  function withdrawInvest(uint256 index) external override secured {
    require(userTotalInvest(_msgSender()) >= MINIMUM_INVEST, "USR");
    require(users[_msgSender()].invest[index].startTime != 0, "VAL");

    (, uint256 daily) = indexInterest(_msgSender(), index);

    uint256 amount = _withdraw(_msgSender(), index);

    uint256 total = amount.add(daily);

    if (tvtUsers[_msgSender()]) {
      _safeTransferTVT(_msgSender(), USDtoTVT(total)); // Transfer TVT to user
    } else {
      _safeTransferBNB(_msgSender(), USDtoBNB(total.sub(FEE))); // Transfer BNB to user
    }

    emit WithdrawInterest(_msgSender(), daily);
    emit WithdrawInvest(_msgSender(), users[_msgSender()].referrer, amount);
  }

  // User API Functions
  function BNBValue(address user) external view override returns (uint256) {
    return user.balance;
  }

  function TVTValue(address user) public view override returns (uint256) {
    return _TVTBalance(user);
  }

  function userDepositNumber(address user) external view override returns (uint256) {
    return users[user].invest.length;
  }

  function userDepositDetails(
    address user,
    uint256 index
  ) external view override returns (uint256 amount, uint256 startTime) {
    amount = users[user].invest[index].amount;
    startTime = users[user].invest[index].startTime;
  }

  function userInvestDetails(
    address user
  ) external view override returns (Invest[] memory) {
    return users[user].invest;
  }
}