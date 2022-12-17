// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

import "./Tokenized.sol";
import "./Payable.sol";
import "./Planed.sol";
import "./IHiVPN.sol";

contract HiVPN is IHiVPN, Payable, Tokenized, Planed {
  using Math for uint256;

  constructor(address[] memory tokens, address[] memory feeds) {
    admin = msg.sender;
    owner = msg.sender;
    batchSetPriceFeeds(tokens, feeds);
  }

  function toToken(
    address token,
    uint256 value
  ) external view override returns (uint256) {
    (uint256 price, uint256 decimals) = _tokenDetails(token);

    return value.mulDecimals(decimals).div(price);
  }

  function toUSD(address token, uint256 value) public view override returns (uint256) {
    (uint256 price, uint256 decimals) = _tokenDetails(token);

    return value.mul(price).divDecimals(decimals);
  }

  function findPlan(uint256 value) public view override returns (uint8 plan) {
    uint lessValue = value.mul(_less.add(100)).div(100);
    uint moreValue = value.mul(100).div(_more.add(100));

    for (uint8 i = 1; i < _planPrices.length; i++) {
      if (lessValue >= _planPrices[i] && moreValue <= _planPrices[i]) plan = i;
    }
  }

  // Payment function
  function pay(
    uint256 id,
    uint256 plan,
    address token,
    uint256 amount,
    address referrer
  ) public payable override {
    require(feedExists(token), "TOK");
    require(payments[id].time == 0, "PAY");
    require(plan > 0 && plan < _planPrices.length, "SLP");

    if (token == address(0)) {
      require(msg.value == amount, "BNB");
    } else {
      require(userTokenAllowance(_msgSender(), token) >= amount, "APR");
    }

    uint256 value = toUSD(token, amount);
    uint8 planIndex = findPlan(value);
    require(planIndex == plan, "PLA");

    uint256 feeValue = amount.mul(_fee).div(100);
    uint256 adminValue = amount.sub(feeValue);

    if (token == address(0)) {
      payable(admin).transfer(adminValue);
    } else {
      bool adminTx = IERC20(token).transferFrom(_msgSender(), admin, adminValue);
      bool ownerTx = IERC20(token).transferFrom(_msgSender(), address(this), feeValue);
      require(adminTx && ownerTx, "TRF");
    }

    payments[id] = Payment({
      token: token,
      value: value,
      amount: amount,
      user: _msgSender(),
      time: block.timestamp,
      planId: _planIds[planIndex]
    });

    paymentList.push(id);

    emit NewPayment(_msgSender(), referrer, id, value);
  }
}