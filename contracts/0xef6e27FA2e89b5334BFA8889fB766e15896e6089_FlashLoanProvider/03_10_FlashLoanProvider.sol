// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './token/ERC20.sol';
import './interfaces/IFlashLoan.sol';
import './interfaces/dydx/DydxFlashloanBase.sol';
import './interfaces/dydx/ICallee.sol';
import './interfaces/IFlashLoan.sol';

contract FlashLoanProvider is ERC20, IFlashLoanProvider, DydxFlashloanBase {
  uint256 public constant FULL_PERCENT = 100_000; // 100%

  event OnFlashLoan(address user, uint256 value, uint256 fee, uint8 flashLoanType);

  bool public initialized;

  uint256 public feePercent;
  bool locked;

  function initialize(string memory name, string memory symbol) public virtual override {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;
    feePercent = 50; // 0.05%

    ERC20.initialize(name, symbol);
  }

  function getPrice() public view returns (uint256 price) {
    require(!locked);
    if (totalSupply == 0) {
      price = 1 ether;
    } else {
      price = (address(this).balance * 1 ether) / totalSupply;
    }
  }

  function deposit() external payable {
    require(!locked);

    uint256 balance = (msg.value * 1 ether) / getPrice();
    balanceOf[msg.sender] += balance;
    totalSupply += balance;

    emit Transfer(address(0), msg.sender, balance);
  }

  function withdraw(uint256 balance) external {
    require(!locked);
    
    balanceOf[msg.sender] -= balance;
    if (totalSupply == balance) {
      totalSupply = 0;
      payable(msg.sender).transfer(address(this).balance);
    } else {
      payable(msg.sender).transfer((balance * getPrice()) / 1 ether);
      totalSupply -= balance;
    }

    emit Transfer(msg.sender, address(0), balance);
  }

  function flashLoan(
    address aggregator,
    uint256 value,
    bytes calldata trades,
    uint8 flashLoanType
  ) external override {
    require(!locked);
    // lock deposit/withdraw
    locked = true;
    // balanceOrigin
    address _this = address(this);
    uint256 balanceOrigin = _this.balance;
    
    require(flashLoanType <= uint8(FlashLoanType.DYDX), "invalid flash loan type");

    uint256 fee;
    if (flashLoanType == uint8(FlashLoanType.DEFAULT)) {
      fee = flashLoanDefault(aggregator, value, trades);
    } else if (flashLoanType == uint8(FlashLoanType.DYDX)) {
      fee = flashLoanDydx(aggregator, value, trades);
    }

    emit OnFlashLoan(msg.sender, value, fee, flashLoanType);

    // balanceAfter
    require(_this.balance >= (balanceOrigin + fee));
    // unlock
    locked = false;
  }

  function flashLoanDefault(
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) internal returns(uint256 fee) {
    fee = (value * feePercent) / FULL_PERCENT;

    // transfer ETH to loaner
    address user = msg.sender;
    payable(user).transfer(value);

    // proceed trades
    IFlashLoanReceiver(user).onFlashLoanReceived(aggregator, value, fee, trades);
  }

  function flashLoanDydx(
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) internal  returns(uint256 fee) {
    ISoloMargin solo = ISoloMargin(SOLO);

    // Get marketId from token address
    /*
    0	WETH
    1	SAI
    2	USDC
    3	DAI
    */
    uint marketId = _getMarketIdFromTokenAddress(SOLO, WETH);

    // Calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(value);

    /*
    1. Withdraw
    2. Call callFunction()
    3. Deposit back
    */

    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, value);
    operations[1] = _getCallAction(
      // Encode FlashLoanDydxData for callFunction
      abi.encode(FlashLoanDydxData({user: msg.sender, aggregator: aggregator, value: value, trades: trades}))
    );
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();
    solo.operate(accountInfos, operations);
  }

  function setFeePercent(uint256 newFeePercent) external {
    require(msg.sender == admin);
    feePercent = newFeePercent;
  }

  receive() external payable {}
}