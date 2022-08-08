// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeTierStrate is Ownable {
  struct FeeRecObj {
    uint256 index;
    string title;
    address account;
    uint256 feePercent;
    bool exist;
  }

  struct ManagerObj {
    uint256 index;
    bool exist;
  }

  uint256 public MAX_FEE = 1000;
  uint256 public MAX_INDEX = 1;
  uint256 private depositFee = 0;
  uint256 private totalFee = 100;
  uint256 private withdrawlFee = 0;
  uint256 private baseFee = 1000;

  mapping (uint256 => FeeRecObj) private _feeTier;
  uint256[] private _tierIndex;

  mapping (address => ManagerObj) private _manageAccess;
  address[] private _feeManager;

  modifier onlyManager() {
    require(msg.sender == owner() || _manageAccess[msg.sender].exist, "!manager");
    _;
  }

  function getAllManager() public view returns(address[] memory) {
    return _feeManager;
  }

  function setManager(address usraddress, bool access) public onlyOwner {
    if (access == true) {
      if ( ! _manageAccess[usraddress].exist) {
        uint256 newId = _feeManager.length;
        _manageAccess[usraddress] = ManagerObj(newId, true);
        _feeManager.push(usraddress);
      }
    }
    else {
      if (_manageAccess[usraddress].exist) {
        address lastObj = _feeManager[_feeManager.length - 1];
        _feeManager[_manageAccess[usraddress].index] = _feeManager[_manageAccess[lastObj].index];
        _feeManager.pop();
        delete _manageAccess[usraddress];
      }
    }
  }

  function getMaxFee() public view returns(uint256) {
    return MAX_FEE;
  }

  function setMaxFee(uint256 newFee) public onlyManager {
    MAX_FEE = newFee;
  }

  function setDepositFee(uint256 newFee) public onlyManager {
    depositFee = newFee;
  }

  function setTotalFee(uint256 newFee) public onlyManager {
    totalFee = newFee;
  }

  function setWithdrawFee(uint256 newFee) public onlyManager {
    withdrawlFee = newFee;
  }

  function setBaseFee(uint256 newFee) public onlyManager {
    baseFee = newFee;
  }

  function getDepositFee() public view returns(uint256, uint256) {
    return (depositFee, baseFee);
  }

  function getTotalFee() public view returns(uint256, uint256) {
    return (totalFee, baseFee);
  }

  function getWithdrawFee() public view returns(uint256, uint256) {
    return (withdrawlFee, baseFee);
  }

  function getAllTier() public view returns(uint256[] memory) {
    return _tierIndex;
  }

  function insertTier(string memory title, address account, uint256 fee) public onlyManager {
    require(fee < MAX_FEE, "Fee tier value is overflowed");
    _tierIndex.push(MAX_INDEX);
    _feeTier[MAX_INDEX] = FeeRecObj(_tierIndex.length - 1, title, account, fee, true);
    MAX_INDEX = MAX_INDEX + 1;
  }

  function getTier(uint256 index) public view returns(address, string memory, uint256) {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    FeeRecObj memory tierItem = _feeTier[index];
    return (tierItem.account, tierItem.title, tierItem.feePercent);
  }

  function updateTier(uint256 index, string memory title, address account, uint256 fee) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    require(fee < MAX_FEE, "Fee tier value is overflowed");
    _feeTier[index].title = title;
    _feeTier[index].account = account;
    _feeTier[index].feePercent = fee;
  }

  function removeTier(uint256 index) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be removed");
    uint256 arr_index = _feeTier[index].index;
    uint256 last_index = _tierIndex[_tierIndex.length-1];
    
    FeeRecObj memory changedObj = _feeTier[last_index];
    _feeTier[last_index] = FeeRecObj(arr_index, changedObj.title, changedObj.account, changedObj.feePercent, true);
    _tierIndex[arr_index] = last_index;
    _tierIndex.pop();
    delete _feeTier[index];
  }
}