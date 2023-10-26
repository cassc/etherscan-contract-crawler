// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWTON } from "../../dao/interfaces/IWTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { DepositManagerStorage } from "./DepositManagerStorage.sol";

interface IOnApprove {
  function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external returns (bool);
}

interface ILayer2Registry {
  function layer2s(address layer2) external view returns (bool);
}

interface ILayer2 {
  function operator() external view returns (address);
}

interface ISeigManager {
  function stakeOf(address layer2, address account) external view returns (uint256);
  function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
  function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);
}

interface IOldDepositManager {
  function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
  function processRequest(address layer2, bool receiveTON) external returns (bool);
}

/**
 * @dev DepositManager manages WTON deposit and withdrawal from operator and WTON holders.
 */
//ERC165
contract DepositManagerForMigration is ProxyStorage, AccessibleCommon, DepositManagerStorage {
  using SafeERC20 for IERC20;

  ////////////////////
  // Modifiers
  ////////////////////

  modifier onlyLayer2(address layer2) {
    require(ILayer2Registry(_registry).layer2s(layer2));
    _;
  }

  modifier onlySeigManager() {
    require(msg.sender == _seigManager);
    _;
  }

  ////////////////////
  // Events
  ////////////////////

  event Deposited(address indexed layer2, address depositor, uint256 amount);
  event WithdrawalRequested(address indexed layer2, address depositor, uint256 amount);
  event WithdrawalProcessed(address indexed layer2, address depositor, uint256 amount);

  // ---------  onlyOwner

  function initialize (
    address wton_,
    address registry_,
    address seigManager_,
    uint256 globalWithdrawalDelay_,
    address oldDepositManager_
  ) external {
    require(_wton == address(0), "already initialized");

    _wton = wton_;
    _registry = registry_;
    _seigManager = seigManager_;
    globalWithdrawalDelay = globalWithdrawalDelay_;
    oldDepositManager = oldDepositManager_;
    _registerInterface(IOnApprove.onApprove.selector);
  }

  function setSeigManager(address seigManager_) external onlyOwner {
    _seigManager = seigManager_;
  }

  function depositWithoutTransfer(address layer2, address[] memory accounts, uint256[] memory amounts)
    external onlyOwner returns (bool) {
    require(accounts.length != 0, 'no account');
    require(accounts.length == amounts.length, 'wrong lenth');

    for (uint256 i = 0; i < accounts.length; i++){
      require(accounts[i] != address(0) && amounts[i] != 0, "zero amount or zero address");
      require(_deposit(layer2, accounts[i], amounts[i]));
    }

    return true;
  }

  function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external onlyOwner {
    globalWithdrawalDelay = globalWithdrawalDelay_;
  }

  function setOldDepositManager(address oldDepositManager_) external onlyOwner {
    oldDepositManager = oldDepositManager_;
  }

  function oldRequestWithdrawal(address layer2, uint256 amounts) external onlyOwner returns (bool) {
    require(IERC20(_wton).balanceOf(oldDepositManager) >= amounts, "excceed the oldDepositManager's balance");
    return IOldDepositManager(oldDepositManager).requestWithdrawal(layer2, amounts);
  }

  function oldProcessRequest(address layer2) external onlyOwner returns (bool) {
    return IOldDepositManager(oldDepositManager).processRequest(layer2, false);
  }

  // ---------  external


  // --------- internal

  function _deposit(address layer2, address account, uint256 amount) internal onlyLayer2(layer2) returns (bool) {
    _accStaked[layer2][account] = _accStaked[layer2][account] + amount;
    _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + amount;
    _accStakedAccount[account] = _accStakedAccount[account] + amount;

    // IERC20(_wton).safeTransferFrom(payer, address(this), amount);

    emit Deposited(layer2, account, amount);

    require(ISeigManager(_seigManager).onDeposit(layer2, account, amount));

    return true;
  }

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == ILayer2(layer2).operator();
  }

  function requestWithdrawalWithDelay(address layer2, address account, uint256 amount, uint256 delayBlock) external onlyOwner returns (bool) {
    return _requestWithdrawal(layer2, account, amount, delayBlock);
  }

  function _requestWithdrawal(address layer2, address account, uint256 amount, uint256 delayBlock) internal onlyLayer2(layer2) returns (bool) {
    require(amount > 0, "DepositManager: amount must not be zero");

    _withdrawalRequests[layer2][account].push(WithdrawalReqeust({
      withdrawableBlockNumber: uint128(block.number + delayBlock),
      amount: uint128(amount),
      processed: false
    }));

    _pendingUnstaked[layer2][account] = _pendingUnstaked[layer2][account] + amount;
    _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] + amount;
    _pendingUnstakedAccount[account] = _pendingUnstakedAccount[account] + amount;

    emit WithdrawalRequested(layer2, account, amount);

    require(ISeigManager(_seigManager).onWithdraw(layer2, account, amount));

    return true;
  }

  ////////////////////
  // Storage getters
  ////////////////////

  // solium-disable
  function wton() external view returns (address) { return _wton; }
  function registry() external view returns (address) { return _registry; }
  function seigManager() external view returns (address) { return _seigManager; }

  function accStaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _accStaked[layer2][account]; }
  function accStakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _accStakedLayer2[layer2]; }
  function accStakedAccount(address account) external view returns (uint256 wtonAmount) { return _accStakedAccount[account]; }

  function pendingUnstaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _pendingUnstaked[layer2][account]; }
  function pendingUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _pendingUnstakedLayer2[layer2]; }
  function pendingUnstakedAccount(address account) external view returns (uint256 wtonAmount) { return _pendingUnstakedAccount[account]; }

  function accUnstaked(address layer2, address account) external view returns (uint256 wtonAmount) { return _accUnstaked[layer2][account]; }
  function accUnstakedLayer2(address layer2) external view returns (uint256 wtonAmount) { return _accUnstakedLayer2[layer2]; }
  function accUnstakedAccount(address account) external view returns (uint256 wtonAmount) { return _accUnstakedAccount[account]; }

  function withdrawalRequestIndex(address layer2, address account) external view returns (uint256 index) { return _withdrawalRequestIndex[layer2][account]; }
  function withdrawalRequest(address layer2, address account, uint256 index) external view returns (uint128 withdrawableBlockNumber, uint128 amount, bool processed ) {
    withdrawableBlockNumber = _withdrawalRequests[layer2][account][index].withdrawableBlockNumber;
    amount = _withdrawalRequests[layer2][account][index].amount;
    processed = _withdrawalRequests[layer2][account][index].processed;
  }

  // solium-enable
}