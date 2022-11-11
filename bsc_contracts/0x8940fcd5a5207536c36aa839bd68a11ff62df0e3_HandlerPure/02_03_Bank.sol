// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.17;

import "./Data.sol";

contract Bank is Data {

  function initiateDistribute() external hasAccount(msg.sender) {
    uint amount = distribute(systemBalance);

    systemBalance -= amount;
  }

  function distribute(uint _amount) internal returns (uint) {
    require(_amount > 0, "No amount transferred");

    uint amount = _amount - (_amount % 100);
    uint percentage = amount / 100;
    uint total_used = 0;
    uint pay = 0;

    for (uint num = 0; num < totalHolders;num++) {
      pay = percentage * accountStorage[accountLookup[num]].percentage;

      if (pay > 0) {
        if ((total_used + pay) > amount) { //Ensure we do not pay out too much
          pay = amount - total_used;
        }

        deposit(accountLookup[num], pay);
        total_used += pay;
      }

      if (total_used >= amount) { //Ensure we stop if we have paid out everything
        break;
      }
    }

    return total_used;
  }

  function deposit(address _to, uint _amount) internal hasAccount(_to) {
    accountStorage[_to].amount += _amount;
  }

  fallback() external payable {
    systemBalance += msg.value;
  }

  receive() external payable {
    systemBalance += msg.value;
  }

  function getSystemBalance() external view hasAccount(msg.sender) returns (uint) {
    return systemBalance;
  }

  function getBalance() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].amount;
  }

  function getReceived() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].received;
  }
  
  function withdraw(uint _amount) external payable hasAccount(msg.sender) canWithdraw(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount -= _amount;
    accountStorage[msg.sender].received += _amount;

    (bool success, ) = msg.sender.call{value: _amount}("");
    
    require(success, "Transfer failed");
  }

  function withdrawTo(address payable _to, uint _amount) external hasAccount(msg.sender) canWithdraw(msg.sender) blockReEntry() {
    require(accountStorage[msg.sender].amount >= _amount && _amount > 0, "Not enough funds");

    accountStorage[msg.sender].amount -= _amount;
    accountStorage[msg.sender].received += _amount;

    (bool success, ) = _to.call{value: _amount}("");
    
    require(success, "Transfer failed");
  }

  function subPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
      accountStorage[_addr].percentage -= _percentage;
    }

  function addPercentage(address _addr, uint _percentage) internal hasAccount(_addr) {
    accountStorage[_addr].percentage += _percentage;
  }

  function getPercentage() external view hasAccount(msg.sender) returns (uint) {
    return accountStorage[msg.sender].percentage;
  }

  function validateBalance() external hasAccount(msg.sender) returns (uint) { //Allow any account to verify/adjust contract balance
    uint amount = systemBalance;

    for (uint num = 0; num < totalHolders;num++) {
      amount += accountStorage[accountLookup[num]].amount;
    }

    if (amount < address(this).balance) {
      uint balance = address(this).balance;
      balance -= amount;

      systemBalance += balance;

      return balance;
    }

    return 0;
  }

  function createAccount(address _addr, uint _amount, uint _percentage, uint _agreementAmount, bool _withdraw) internal {
    accountStorage[_addr] = Account({amount: _amount, received: 0, percentage: _percentage, withdraw: _withdraw, exists: true});
    agreementAmount[totalHolders] = _agreementAmount;
    accountLookup[totalHolders++] = _addr;
  }

  function deleteAccount(address _addr, address _to) internal hasAccount(_addr) {
    deposit(_to, accountStorage[_addr].amount);

    for (uint8 num = 0; num < totalHolders;num++) {
      if (accountLookup[num] == _addr) {
        delete(accountLookup[num]);
        break;
      }
    }

    delete(accountStorage[_addr]);
  }
}