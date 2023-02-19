// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./StratManagerUpgradeable.sol";

abstract contract DynamicFeeManager is Initializable, StratManagerUpgradeable {
  uint256 public constant MAX_FEE = 1000;
  uint256 public constant MAX_CALL_FEE = 111;

  uint256 public constant WITHDRAWAL_FEE_CAP = 50;
  uint256 public constant WITHDRAWAL_MAX = 10000;

  uint256 public withdrawalFee;
  uint256 public callFee;
  uint256 public strategistFee;
  uint256 public fee1;
  uint256 public fee2;

  function __DynamicFeeManager_init() internal initializer {
    __DynamicFeeManager_init_unchained();
  }

  function __DynamicFeeManager_init_unchained() internal initializer {
    withdrawalFee = 0;
    callFee = 0;
    strategistFee = 0;
    fee1 = 350;
    fee2 = 650;
  }

  function setFee(
    uint256 _callFee,
    uint256 _strategistFee,
    uint256 _fee2
  ) public onlyManager {
    require(_callFee <= MAX_CALL_FEE, "!cap");
    uint256 sum = _callFee + _strategistFee + _fee2;
    require(sum <= 1000, "Invalid Fee Combination (Please add total fee less than 1000)");

    callFee = _callFee;
    strategistFee = _strategistFee;
    fee2 = _fee2;

    fee1 = MAX_FEE - sum;
  }

  function setWithdrawalFee(uint256 _fee) public onlyManager {
    require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

    withdrawalFee = _fee;
  }
}