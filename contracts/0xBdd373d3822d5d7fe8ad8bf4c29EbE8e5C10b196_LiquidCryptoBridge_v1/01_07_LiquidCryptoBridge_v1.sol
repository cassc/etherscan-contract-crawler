// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint256 wad) external;
}

contract LiquidCryptoBridge_v1 is ERC20, Ownable {
  uint256 public swapFee = 50;
  uint256 public feeBase = 1000;
  address public feeCollector;
  address public weth;

  struct SwapVoucher {
    address account;
    bool isContract;
    uint256 inChain;
    uint256 inAmount;
    uint256 outChain;
    uint256 outAmount;
  }
  mapping (uint256 => SwapVoucher) public voucherLists;
  mapping (address => bool) public managers;

  event tokenDeposit(uint256 inAmount,  uint256 fee, uint256 gas);
  event tokenWithdraw(address account, uint256 amount, uint256 out, uint256 fee, uint256 gas);
  event tokenRefund(address account, uint256 out);

  constructor(address _weth, address _feeCollector)
    ERC20("LiquidCryptoBridgeLP_v1", "LCBLPv1")
  {
    weth = _weth;
    feeCollector = _feeCollector;
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  function depositForUser(uint256 fee) public payable {
    uint256 totalAmount = msg.value;
    uint256 feeAmount = (totalAmount - fee) * swapFee / feeBase;
    if (feeAmount > 0) {
      _mint(feeCollector, feeAmount);
    }

    emit tokenDeposit(totalAmount, feeAmount, fee);

    if (fee > 0) {
      (bool success1, ) = tx.origin.call{value: fee}("");
      require(success1, "Failed to refund fee");
    }
  }
  
  function withdrawForUser(address account, bool isContract, uint256 outAmount, uint256 fee) public onlyManager {
    uint256 feeAmount = (outAmount - fee) * swapFee / feeBase;
    uint256 withdrawAmount = outAmount - feeAmount - fee;
    require(withdrawAmount <= address(this).balance, "Not enough balance");
    if (feeAmount > 0) {
      _mint(feeCollector, feeAmount);
    }

    if (isContract) {
      IWETH(weth).deposit{value: withdrawAmount}();
      ERC20(weth).transfer(account, withdrawAmount);
    }
    else {
      (bool success1, ) = account.call{value: withdrawAmount}("");
      require(success1, "Failed to withdraw");
    }

    if (fee > 0) {
      (bool success2, ) = tx.origin.call{value: fee}("");
      require(success2, "Failed to refund fee");
    }
    
    emit tokenWithdraw(account, outAmount, withdrawAmount, feeAmount, fee);
  }

  function refundFaildVoucher(address account, bool isContract, uint256 amount, uint256 fee) public onlyManager {
    if (isContract) {
      IWETH(weth).deposit{value: amount}();
      ERC20(weth).transfer(account, amount);
    }
    else {
      (bool success1, ) = account.call{value: amount}("");
      require(success1, "Failed to refund");
    }
    
    if (fee > 0) {
      (bool success2, ) = tx.origin.call{value: fee}("");
      require(success2, "Failed to refund fee");
    }

    emit tokenRefund(account, amount);
  }

  function setFee(uint256 fee) public onlyOwner {
    swapFee = fee;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function deposit() public payable onlyOwner {
    if (totalSupply() > address(this).balance) {
      uint256 needAmount = totalSupply() - address(this).balance;
      if (msg.value > needAmount) {
        uint256 refund = msg.value - needAmount;
        (bool success1, ) = msg.sender.call{value: refund}("");
        require(success1, "Failed to refund unnecessary balance");
      }
    }
  }

  function withdraw() public onlyOwner {
    if (totalSupply() < address(this).balance) {
      uint256 availableAmount = address(this).balance - totalSupply();
      (bool success1, ) = msg.sender.call{value: availableAmount}("");
      require(success1, "Failed to refund unnecessary balance");
    }
  }

  function stake() public payable {
    _mint(msg.sender, msg.value);
  }

  function unstake(uint256 amount) public {
    uint256 totalReward = balanceOf(feeCollector);
    uint256 reward = amount * totalReward / totalSupply();
    uint256 unstakeAmount = amount + reward;
    require(unstakeAmount <= address(this).balance, "Not enough balance");
    (bool success1, ) = msg.sender.call{value: unstakeAmount}("");
    require(success1, "Failed to unstake");
    _burn(msg.sender, amount);
    _burn(feeCollector, reward);
  }
}