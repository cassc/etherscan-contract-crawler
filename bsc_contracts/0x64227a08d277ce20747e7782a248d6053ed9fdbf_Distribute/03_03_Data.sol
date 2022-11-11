// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.17;

contract Data {

  struct Account {
    uint amount;
    uint received;
    uint percentage;
    bool exists;
    bool withdraw;
  }
  
  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal totalHolders;
  uint internal reEntryStatus;
  uint internal systemBalance = 0;
  
  address internal owner;
  
  mapping(uint => uint) internal agreementAmount;
  mapping(uint => address) internal accountLookup;
  mapping(address => address) internal transferTo;
  mapping(address => Account) internal accountStorage;  

  modifier hasAccount(address _addr) {
    require(accountStorage[_addr].exists, "Restricted Access!");
    _;
  }

  modifier blockReEntry() {      
    require(reEntryStatus != ENTRY_DISABLED, "Security Block");
    reEntryStatus = ENTRY_DISABLED;

    _;

    reEntryStatus = ENTRY_ENABLED;
  }

  modifier canWithdraw(address _addr) {
    require(accountStorage[_addr].withdraw, "Restricted Access!");
    _;
  }

  modifier isOwner(address _addr) {
    require(owner == _addr, "Restricted Access!");
    _;
  }

  modifier canTransfer(address _addr) {
    require(accountStorage[_addr].exists == true && accountStorage[_addr].withdraw == false, "Restricted Access!");
    _;
  }
}