// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './token/ERC20.sol';
import './interfaces/IFlashLoan.sol';

contract FlashLoanProvider is ERC20, IFlashLoanProvider {
  uint256 public constant FULL_PERCENT = 100_000; // 100%

  event OnFlashLoan(address user, uint256 value, uint256 fee);

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
      totalSupply -= balance;
      payable(msg.sender).transfer((balance * getPrice()) / 1 ether);
    }

    emit Transfer(msg.sender, address(0), balance);
  }

  function flashLoan(
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) external override {
    require(!locked);
    // lock deposit/withdraw
    locked = true;

    address _this = address(this);
    uint256 balanceOrigin = _this.balance;
    uint256 fee = (value * feePercent) / FULL_PERCENT;

    // transfer ETH to loaner
    address user = msg.sender;
    payable(user).transfer(value);

    // proceed trades
    IFlashLoanReceiver(user).onFlashLoanReceived(aggregator, value, fee, trades);

    require(_this.balance >= (balanceOrigin + fee));
    emit OnFlashLoan(user, value, fee);

    // unlock
    locked = false;
  }

  function setFeePercent(uint256 newFeePercent) external {
    require(msg.sender == admin);
    feePercent = newFeePercent;
  }

  receive() external payable {}
}