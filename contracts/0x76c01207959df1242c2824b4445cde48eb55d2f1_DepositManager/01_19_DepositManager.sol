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

/**
 * @dev DepositManager manages WTON deposit and withdrawal from operator and WTON holders.
 */
//ERC165
contract DepositManager is ProxyStorage, AccessibleCommon, DepositManagerStorage {
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

  ////////////////////
  // SeiManager function
  ////////////////////

  function setSeigManager(address seigManager_) external onlyOwner {
    _seigManager = seigManager_;
  }

  ////////////////////
  // ERC20 Approve callback
  ////////////////////

  function onApprove(
    address owner,
    address spender,
    uint256 amount,
    bytes calldata data
  ) external returns (bool) {
    require(msg.sender == _wton, "DepositManager: only accept WTON approve callback");

    address layer2 = _decodeDepositManagerOnApproveData(data);
    require(_deposit(layer2, owner, amount, owner));

    return true;
  }

  function _decodeDepositManagerOnApproveData(
    bytes memory data
  ) internal pure returns (address layer2) {
    require(data.length == 0x20);

    assembly {
      layer2 := mload(add(data, 0x20))
    }
  }

  ////////////////////
  // Deposit function
  ////////////////////

  /**
   * @dev deposit `amount` WTON in RAY
   */

  function deposit(address layer2, uint256 amount) external returns (bool) {
    require(_deposit(layer2, msg.sender, amount, msg.sender));
    return true;
  }

  function deposit(address layer2, address account, uint256 amount) external returns (bool) {
    require(_deposit(layer2, account, amount, msg.sender));
    return true;
  }

  function deposit(address layer2, address[] memory accounts, uint256[] memory amounts) external returns (bool) {
    require(accounts.length != 0, 'no account');
    require(accounts.length == amounts.length, 'wrong lenth');

    for (uint256 i = 0; i < accounts.length; i++){
      require(_deposit(layer2, accounts[i], amounts[i], msg.sender));
    }

    return true;
  }

  function _deposit(address layer2, address account, uint256 amount, address payer) internal onlyLayer2(layer2) returns (bool) {
    require(account != address(0) && amount != 0, "zero amount or zero address");
    _accStaked[layer2][account] = _accStaked[layer2][account] + amount;
    _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + amount;
    _accStakedAccount[account] = _accStakedAccount[account] + amount;

    IERC20(_wton).safeTransferFrom(payer, address(this), amount);

    emit Deposited(layer2, account, amount);

    require(ISeigManager(_seigManager).onDeposit(layer2, account, amount));

    return true;
  }

  ////////////////////
  // Re-deposit function
  ////////////////////

  /**
   * @dev re-deposit pending requests in the pending queue
   */

  function redeposit(address layer2) external returns (bool) {
    uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
    require(_redeposit(layer2, i, 1));
    return true;
  }

  function redepositMulti(address layer2, uint256 n) external returns (bool) {
    uint256 i = _withdrawalRequestIndex[layer2][msg.sender];
    require(_redeposit(layer2, i, n));
    return true;
  }

  function _redeposit(address layer2, uint256 i, uint256 n) internal onlyLayer2(layer2) returns (bool) {
    uint256 accAmount;

    require(_withdrawalRequests[layer2][msg.sender].length > 0, "DepositManager: no request");
    require(_withdrawalRequests[layer2][msg.sender].length - i >= n, "DepositManager: n exceeds num of pending requests");

    uint256 e = i + n;
    for (; i < e; i++) {
      WithdrawalReqeust storage r = _withdrawalRequests[layer2][msg.sender][i];
      uint256 amount = r.amount;

      require(!r.processed, "DepositManager: pending request already processed");
      require(amount > 0, "DepositManager: no valid pending request");

      accAmount = accAmount + amount;
      r.processed = true;
    }


    // deposit-related storages
    _accStaked[layer2][msg.sender] = _accStaked[layer2][msg.sender] + accAmount;
    _accStakedLayer2[layer2] = _accStakedLayer2[layer2] + accAmount;
    _accStakedAccount[msg.sender] = _accStakedAccount[msg.sender] + accAmount;

    // withdrawal-related storages
    _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - accAmount;
    _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - accAmount;
    _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - accAmount;

    _withdrawalRequestIndex[layer2][msg.sender] += n;

    emit Deposited(layer2, msg.sender, accAmount);

    require(ISeigManager(_seigManager).onDeposit(layer2, msg.sender, accAmount));

    return true;
  }

  ////////////////////
  // Slash functions
  ////////////////////

  function slash(address layer2, address recipient, uint256 amount) external onlySeigManager returns (bool) {
    //return _wton.transferFrom(owner, recipient, amount);
  }

  ////////////////////
  // Setter
  ////////////////////

  function setGlobalWithdrawalDelay(uint256 globalWithdrawalDelay_) external onlyOwner {
    globalWithdrawalDelay = globalWithdrawalDelay_;
  }

  function setWithdrawalDelay(address l2chain, uint256 withdrawalDelay_) external {
    require(_isOperator(l2chain, msg.sender));
    withdrawalDelay[l2chain] = withdrawalDelay_;
  }

  ////////////////////
  // Withdrawal functions
  ////////////////////

  function requestWithdrawal(address layer2, uint256 amount) external returns (bool) {
    return _requestWithdrawal(layer2, amount, getDelayBlocks(layer2));
  }

  function _requestWithdrawal(address layer2, uint256 amount, uint256 delay) internal onlyLayer2(layer2) returns (bool) {
    require(amount > 0, "DepositManager: amount must not be zero");
    // uint256 delay = globalWithdrawalDelay > withdrawalDelay[layer2] ? globalWithdrawalDelay : withdrawalDelay[layer2];
    _withdrawalRequests[layer2][msg.sender].push(WithdrawalReqeust({
      withdrawableBlockNumber: uint128(block.number + delay),
      amount: uint128(amount),
      processed: false
    }));

    _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] + amount;
    _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] + amount;
    _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] + amount;

    emit WithdrawalRequested(layer2, msg.sender, amount);

    require(ISeigManager(_seigManager).onWithdraw(layer2, msg.sender, amount));

    return true;
  }

  function processRequest(address layer2, bool receiveTON) external returns (bool) {
    return _processRequest(layer2, receiveTON);
  }

  function _processRequest(address layer2, bool receiveTON) internal returns (bool) {
    uint256 index = _withdrawalRequestIndex[layer2][msg.sender];
    require(_withdrawalRequests[layer2][msg.sender].length > index, "DepositManager: no request to process");

    WithdrawalReqeust storage r = _withdrawalRequests[layer2][msg.sender][index];

    require(r.withdrawableBlockNumber <= block.number, "DepositManager: wait for withdrawal delay");
    r.processed = true;

    _withdrawalRequestIndex[layer2][msg.sender] += 1;

    uint256 amount = r.amount;

    _pendingUnstaked[layer2][msg.sender] = _pendingUnstaked[layer2][msg.sender] - amount;
    _pendingUnstakedLayer2[layer2] = _pendingUnstakedLayer2[layer2] - amount;
    _pendingUnstakedAccount[msg.sender] = _pendingUnstakedAccount[msg.sender] - amount;

    _accUnstaked[layer2][msg.sender] = _accUnstaked[layer2][msg.sender] + amount;
    _accUnstakedLayer2[layer2] = _accUnstakedLayer2[layer2] + amount;
    _accUnstakedAccount[msg.sender] = _accUnstakedAccount[msg.sender] + amount;

    if (receiveTON) {
      require(IWTON(_wton).swapToTONAndTransfer(msg.sender, amount));
    } else {
      IERC20(_wton).safeTransfer(msg.sender, amount);
    }

    emit WithdrawalProcessed(layer2, msg.sender, amount);
    return true;
  }

  function requestWithdrawalAll(address layer2) external onlyLayer2(layer2) returns (bool) {
    uint256 amount = ISeigManager(_seigManager).stakeOf(layer2, msg.sender);
    return _requestWithdrawal(layer2, amount, getDelayBlocks(layer2));
  }

  function processRequests(address layer2, uint256 n, bool receiveTON) external returns (bool) {
    for (uint256 i = 0; i < n; i++) {
      require(_processRequest(layer2, receiveTON));
    }
    return true;
  }

  function numRequests(address layer2, address account) external view returns (uint256) {
    return _withdrawalRequests[layer2][account].length;
  }

  function numPendingRequests(address layer2, address account) external view returns (uint256) {
    uint256 numRequests_ = _withdrawalRequests[layer2][account].length;
    uint256 index = _withdrawalRequestIndex[layer2][account];

    if (numRequests_ == 0) return 0;

    return numRequests_ - index;
  }

  function _isOperator(address layer2, address operator) internal view returns (bool) {
    return operator == ILayer2(layer2).operator();
  }

  function getDelayBlocks(address layer2) public view returns (uint256){
    return  globalWithdrawalDelay > withdrawalDelay[layer2] ? globalWithdrawalDelay : withdrawalDelay[layer2];
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