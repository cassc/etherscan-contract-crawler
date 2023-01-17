// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { AutomateBase } from "./AutomateBase.sol";
import { ConfirmedOwner } from "./ConfirmedOwner.sol";
import { IReceiver } from "./interfaces/IReceiver.sol";
import { IAggregatorV3 } from "./interfaces/IAggregatorV3.sol";
import { IVersion } from "./interfaces/IVersion.sol";
import { IAutomateCompatible } from "./interfaces/IAutomateCompatible.sol";
import { Config, State, IAutomateRegistryExecutable } from "./interfaces/IAutomateRegistry.sol";

/**
 * @notice Registry for adding work for Ankr Automates to perform on client
 * contracts. Clients must support the Task interface.
 */
contract AutomateRegistry is
  IVersion,
  IReceiver,
  IAutomateRegistryExecutable,
  AutomateBase,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  address private constant ZERO_ADDRESS = address(0);
  address private constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 private constant CHECK_SELECTOR = IAutomateCompatible.checkTask.selector;
  bytes4 private constant PERFORM_SELECTOR = IAutomateCompatible.performTask.selector;
  uint256 private constant PERFORM_GAS_MIN = 2_300;
  uint256 private constant CANCELATION_DELAY = 50;
  uint256 private constant PERFORM_GAS_CUSHION = 5_000;
  uint256 private constant REGISTRY_GAS_OVERHEAD = 80_000;
  uint256 private constant PPB_BASE = 1_000_000_000;
  uint64 private constant UINT64_MAX = 2**64 - 1;

  address[] private _automateList;
  EnumerableSetUpgradeable.UintSet private _taskIDs;
  mapping(uint256 => Task) private _task;
  mapping(address => AutomateInfo) private _automateInfo;
  mapping(address => address) private _proposedPayee;
  mapping(uint256 => bytes) private _checkData;
  Storage private _storage;
  uint256 private _defaultGasPrice; // not in config object for gas savings
  uint256 private _ownerBNBBalance;
  uint256 private _expectedBNBBalance;
  address private _registrar;

  mapping(address => uint256) private _userBalance;
  mapping(address => EnumerableSetUpgradeable.UintSet) private _userTasks;

  IAggregatorV3 public FAST_GAS_FEED;

  string public constant override version = "AutomateRegistry 1.0.0";

  error CannotCancel();
  error TaskNotActive();
  error TaskNotCanceled();
  error TaskNotNeeded();
  error NotAContract();
  error OnlyActiveAutomates();
  error InsufficientFunds();
  error AutomatesMustTakeTurns();
  error ParameterLengthError();
  error OnlyOwnerOrAdmin();
  error InvalidPayee();
  error DuplicateEntry();
  error ValueNotChanged();
  error IndexOutOfRange();
  error ArrayHasNoEntries();
  error GasLimitOutsideRange();
  error OnlyByPayee();
  error OnlyByProposedPayee();
  error GasLimitCanOnlyIncrease();
  error OnlyByAdmin();
  error OnlyByOwnerOrregistrar();
  error InvalidRecipient();
  error InvalidDataLength();
  error TargetCheckReverted(bytes reason);
  error TaskPaused();

  /**
   * @notice storage of the registry, contains a mix of config and state data
   */
  struct Storage {
    uint32 paymentFee;
    uint32 flatFee;
    uint24 blockCountPerAutomate; 
    uint32 gasLimit;
    uint24 lastFeedSecondsAmt;
    uint16 gasMultiplier;
    uint32 maxGas;
    uint32 nonce;
    uint256 minTaskSpend;
  }

  struct Task {
    uint256 balance;
    address lastAutomate;
    uint32 executeGas;
    uint64 maxValidBlocknumber;
    uint256 amountSpent;
    address target;
    address admin;
    bool isPaused;
    uint256 startTime;
  }

  struct AutomateInfo {
    address payee;
    uint256 balance;
    bool active;
  }

  struct PerformParams {
    address from;
    uint256 id;
    bytes performData;
    uint256 maxNativePayment;
    uint256 gasLimit;
    uint256 adjustedGasWei;
  }

  event TaskRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event TaskPerformed(
    uint256 indexed id,
    bool indexed success,
    address indexed from,
    uint256 payment,
    bytes performData
  );
  event TaskCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event FundsAdded(uint256 indexed id, address indexed from, uint256 amount);
  event FundsAddedToUser(address indexed user, address indexed from, uint256 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event FundsWithdrawnForUser(address indexed user, uint256 amount, address to);
  event OwnerFundsWithdrawn(uint256 amount);
  event TaskMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event TaskReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event ConfigSet(Config config);
  event AutomatesUpdated(address[] automates, address[] payees);
  event PaymentWithdrawn(
    address indexed automate,
    uint256 indexed amount,
    address indexed to,
    address payee
  );
  event PayeeshipTransferRequested(
    address indexed automate,
    address indexed from,
    address indexed to
  );
  event PayeeshipTransferred(address indexed automate, address indexed from, address indexed to);
  event TaskGasLimitSet(uint256 indexed id, uint256 gasLimit);

  /**
   * @param fastGasFeed address of the Fast Gas price feed
   * @param config registry config settings
   */
  function initialize(
    address fastGasFeed, 
    Config memory config
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    FAST_GAS_FEED = IAggregatorV3(fastGasFeed);
    setConfig(config);
  }

  // ACTIONS

  /**
   * @notice adds a new task
   * @param target address to perform task on
   * @param gasLimit amount of gas to provide the target contract when
   * performing task
   * @param admin address to cancel task and withdraw remaining funds
   * @param checkData data passed to the contract when checking for task
   */
  function registerTask(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    uint256 startTime
  ) external override onlyOwnerOrregistrar returns (uint256 id) {
    id = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), _storage.nonce))
    );
    _createTask(id, target, gasLimit, admin, 0, checkData, startTime);
    _storage.nonce++;
    emit TaskRegistered(id, gasLimit, admin);
    return id;
  }

  /**
   * @notice simulated by automates via eth_call to see if the task needs to be
   * performed. If task is needed, the call then simulates performTask
   * to make sure it succeeds. Finally, it returns the success status along with
   * payment information and the perform data payload.
   * @param id identifier of the task to check
   * @param from the address to simulate performing the task from
   */
  function checkTask(uint256 id, address from)
    external
    override
    notExecute
    returns (
      bytes memory performData,
      uint256 maxNativePayment,
      uint256 gasLimit,
      uint256 adjustedGasWei
    )
  {
    Task memory task = _task[id];
    if (task.isPaused) revert TaskPaused();
    if (task.startTime > block.timestamp) revert TaskNotActive();

    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, _checkData[id]);
    (bool success, bytes memory result) = task.target.call{ gas: _storage.gasLimit }(
      callData
    );

    if (!success) revert TargetCheckReverted(result);

    (success, performData) = abi.decode(result, (bool, bytes));
    if (!success) revert TaskNotNeeded();

    PerformParams memory params = _generatePerformParams(from, id, performData, false);
    _prePerformTask(task, params.from, params.maxNativePayment);

    return (performData, params.maxNativePayment, params.gasLimit, params.adjustedGasWei);
  }

  /**
   * @notice executes the task with the perform data returned from
   * checkTask, validates the automate's permissions, and pays the automate.
   * @param id identifier of the task to execute the data with.
   * @param performData calldata parameter to be passed to the target task.
   */
  function performTask(uint256 id, bytes calldata performData)
    external
    override
    whenNotPaused
    returns (bool success)
  {
    if (_task[id].isPaused) revert TaskPaused();
    return _performTaskWithParams(_generatePerformParams(msg.sender, id, performData, true));
  }

  function pauseTask(uint256 id) external onlyActiveTask(id) onlyOwnerOrAdmin(id) {
    _task[id].isPaused = true;
  }

  function unpauseTask(uint256 id) external onlyActiveTask(id) onlyOwnerOrAdmin(id) {
    _task[id].isPaused = false;
  }

  /**
   * @notice prevent an task from being performed in the future
   * @param id task to be canceled
   */
  function cancelTask(uint256 id) external override {
    uint64 maxValid = _task[id].maxValidBlocknumber;
    bool canceled = maxValid != UINT64_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && maxValid > block.number)) revert CannotCancel();
    if (!isOwner && msg.sender != _task[id].admin) revert OnlyOwnerOrAdmin();

    uint256 height = block.number;
    if (!isOwner) {
      height = height + CANCELATION_DELAY;
    }
    _userTasks[_task[id].admin].remove(id);
    _task[id].maxValidBlocknumber = uint64(height);
    _taskIDs.remove(id);

    emit TaskCanceled(id, uint64(height));
  }

  /**
   * @notice adds BNB funding for an task by transferring from the sender's
   * BNB balance
   * @param id task to fund
   */
  function addFunds(uint256 id) external payable override onlyActiveTask(id) {
    uint256 amount = msg.value;
    _task[id].balance += amount;
    _expectedBNBBalance += amount;
    emit FundsAdded(id, msg.sender, amount);
  }

  function addUserFunds(address userToFund) external payable {
    require(userToFund != address(0), "cannot fund zero address");
    uint256 amount = msg.value;
    _userBalance[userToFund] += amount;
    _expectedBNBBalance += amount;
    emit FundsAddedToUser(userToFund, msg.sender, amount);
  }

  // TODO: needs to be changed in case of ANKR Token
  /**
   * @notice uses Native's transferAndCall to BNB and add funding to an task
   */
  function transferWithData(bytes calldata data) 
  external 
  payable 
  override 
  whenNotPaused
  returns (bool) {
    uint256 amount = msg.value;
    address sender = msg.sender;
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (_task[id].maxValidBlocknumber != UINT64_MAX) revert TaskNotActive();

    _task[id].balance += amount;
    _expectedBNBBalance += amount;

    emit FundsAdded(id, sender, amount);
    return true;
  }

  /**
   * @notice removes funding from a canceled task
   * @param id task to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(uint256 id, address to) external validRecipient(to) onlyTaskAdmin(id) {
    if (_task[id].maxValidBlocknumber > block.number) revert TaskNotCanceled();

    uint256 minTaskSpend = _storage.minTaskSpend;
    uint256 amountLeft = _task[id].balance;
    uint256 amountSpent = _task[id].amountSpent;

    uint256 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minTaskSpend - amountSpent,0), amountLeft)
    if (amountSpent < minTaskSpend) {
      cancellationFee = minTaskSpend - amountSpent;
      if (cancellationFee > amountLeft) {
        cancellationFee = amountLeft;
      }
    }
    uint256 amountToWithdraw = amountLeft - cancellationFee;

    _task[id].balance = 0;
    _ownerBNBBalance += cancellationFee;

    _expectedBNBBalance -= amountToWithdraw;
    emit FundsWithdrawn(id, amountToWithdraw, to);

    payable(to).transfer(amountToWithdraw);
  }

  function withdrawUserFunds(uint256 amount, address to) external validRecipient(to) {
    address sender = msg.sender;
    if (amount == type(uint256).max) {
      amount = _userBalance[sender];
    } else {
      require(_userBalance[sender] >= amount, "cannot withdraw more amount that user has");
    }
    unchecked {
      _userBalance[sender] -= amount;
    }
    emit FundsWithdrawnForUser(msg.sender, amount, to);

    payable(to).transfer(amount);
  }

  /**
   * @notice withdraws Native funds collected through cancellation fees
   */
  function withdrawOwnerFunds() external onlyOwner {
    uint256 amount = _ownerBNBBalance;

    _expectedBNBBalance -= amount;
    _ownerBNBBalance = 0;

    emit OwnerFundsWithdrawn(amount);
    payable(msg.sender).transfer(amount);
  }

  /**
   * @notice allows the admin of an task to modify gas limit
   * @param id task to be change the gas limit for
   * @param gasLimit new gas limit for the task
   */
  function setTaskGasLimit(uint256 id, uint32 gasLimit)
    external
    override
    onlyActiveTask(id)
    onlyTaskAdmin(id)
  {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > _storage.maxGas)
      revert GasLimitOutsideRange();

    _task[id].executeGas = gasLimit;

    emit TaskGasLimitSet(id, gasLimit);
  }

  /**
   * @notice recovers BNB funds improperly transferred to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gas limit. However, in our anticipated deployment, the number of tasks and
   * automates will be low enough to avoid this problem.
   */
  function recoverFunds() external onlyOwner {
    uint256 total = address(this).balance;
    payable(msg.sender).transfer(total - _expectedBNBBalance);
  }

  /**
   * @notice withdraws an automate's payment, callable only by the automate's payee
   * @param from automate address
   * @param to address to send the payment to
   */
  function withdrawPayment(address from, address to) external validRecipient(to) {
    AutomateInfo memory automate = _automateInfo[from];
    if (automate.payee != msg.sender) revert OnlyByPayee();

    _automateInfo[from].balance = 0;
    _expectedBNBBalance -= automate.balance;
    emit PaymentWithdrawn(from, automate.balance, to, msg.sender);

    payable(to).transfer(automate.balance);
  }

  /**
   * @notice proposes the safe transfer of a automate's payee to another address
   * @param automate address of the automate to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(address automate, address proposed) external {
    if (_automateInfo[automate].payee != msg.sender) revert OnlyByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (_proposedPayee[automate] != proposed) {
      _proposedPayee[automate] = proposed;
      emit PayeeshipTransferRequested(automate, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the safe transfer of payee role for a automate
   * @param automate address to accept the payee role for
   */
  function acceptPayeeship(address automate) external {
    if (_proposedPayee[automate] != msg.sender) revert OnlyByProposedPayee();
    address past = _automateInfo[automate].payee;
    _automateInfo[automate].payee = msg.sender;
    _proposedPayee[automate] = ZERO_ADDRESS;

    emit PayeeshipTransferred(automate, past, msg.sender);
  }

  /**
   * @notice signals to automates that they should not perform tasks until the
   * contract has been unpaused
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice signals to automates that they can perform tasks once again after
   * having been paused
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  // SETTERS

  /**
   * @notice updates the configuration of the registry
   * @param config registry config fields
   */
  function setConfig(Config memory config) public onlyOwner {
    if (config.maxGas < _storage.maxGas) revert GasLimitCanOnlyIncrease();
    _storage = Storage({
      paymentFee: config.paymentFee,
      flatFee: config.flatFee,
      blockCountPerAutomate: config.blockCountPerAutomate, 
      gasLimit: config.gasLimit,
      lastFeedSecondsAmt: config.lastFeedSecondsAmt,
      gasMultiplier: config.gasMultiplier,
      minTaskSpend: config.minTaskSpend,
      maxGas: config.maxGas,
      nonce: _storage.nonce
    });
    _defaultGasPrice = config.defaultGasPrice;
    _registrar = config.registrar;
    emit ConfigSet(config);
  }

  /**
   * @notice update the list of automates allowed to perform task
   * @param automates list of addresses allowed to perform task
   * @param payees addresses corresponding to automates who are allowed to
   * move payments which have been accrued
   */
  function setAutomates(address[] calldata automates, address[] calldata payees) external onlyOwner {
    if (automates.length != payees.length || automates.length < 2) revert ParameterLengthError();
    for (uint256 i = 0; i < _automateList.length; i++) {
      address automate = _automateList[i];
      _automateInfo[automate].active = false;
    }
    for (uint256 i = 0; i < automates.length; i++) {
      address automate = automates[i];
      AutomateInfo storage s_automate = _automateInfo[automate];
      address oldPayee = s_automate.payee;
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) ||
        (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (s_automate.active) revert DuplicateEntry();
      s_automate.active = true;
      if (newPayee != IGNORE_ADDRESS) {
        s_automate.payee = newPayee;
      }
    }
    _automateList = automates;
    emit AutomatesUpdated(automates, payees);
  }

  // GETTERS

  /**
   * @notice read all of the details about an task
   */
  function getTask(uint256 id)
    external
    view
    override
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint256 balance,
      address lastAutomate,
      address admin,
      uint64 maxValidBlocknumber,
      uint256 amountSpent,
      bool isPaused,
      uint256 startTime
    )
  {
    Task memory reg = _task[id];
    return (
      reg.target,
      reg.executeGas,
      _checkData[id],
      reg.balance,
      reg.lastAutomate,
      reg.admin,
      reg.maxValidBlocknumber,
      reg.amountSpent,
      reg.isPaused,
      reg.startTime
    );
  }

  /**
   * @notice retrieve active task IDs
   * @param startIndex starting index in list
   * @param maxCount max count to retrieve (0 = unlimited)
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a wholistic picture of the contract state
   */
  function getActiveTaskIDs(uint256 startIndex, uint256 maxCount)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256 maxIdx = _taskIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = _taskIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice read the current info about any automate address
   */
  function getAutomateInfo(address query)
    external
    view
    override
    returns (
      address payee,
      bool active,
      uint256 balance
    )
  {
    AutomateInfo memory automate = _automateInfo[query];
    return (automate.payee, automate.active, automate.balance);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    override
    returns (
      State memory state,
      Config memory config,
      address[] memory automates
    )
  {
    Storage memory store = _storage;
    state.nonce = store.nonce;
    state.ownerBNBBalance = _ownerBNBBalance;
    state.expectedBNBBalance = _expectedBNBBalance;
    state.numTasks = _taskIDs.length();
    config.paymentFee = store.paymentFee;
    config.flatFee = store.flatFee;
    config.blockCountPerAutomate = store.blockCountPerAutomate; 
    config.gasLimit = store.gasLimit;
    config.lastFeedSecondsAmt = store.lastFeedSecondsAmt;
    config.gasMultiplier = store.gasMultiplier;
    config.minTaskSpend = store.minTaskSpend;
    config.maxGas = store.maxGas;
    config.defaultGasPrice = _defaultGasPrice;
    config.registrar = _registrar;
    return (state, config, _automateList);
  }

  /**
   * @notice calculates the minimum balance required for an task to remain eligible
   * @param id the task id to calculate minimum balance for
   */
  function getMinBalanceForTask(uint256 id) external view returns (uint256 minBalance) {
    return getMaxPaymentForGas(_task[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(uint256 gasLimit) public view returns (uint256 maxPayment) {
    uint256 gasWei = _getFeedData();
    uint256 adjustedGasWei = _adjustGasPrice(gasWei, false);
    return _calculatePaymentAmount(gasLimit, adjustedGasWei);
  }

  function userBalance(address user) external view returns (uint256) {
    return _userBalance[user];
  }

  function userTasks(address user) external view returns (uint256[] memory) {
    return _userTasks[user].values();
  }

  function userTasksCount(address user) external view returns (uint256) {
    return _userTasks[user].length();
  }

  function userTasksAt(address user, uint256 index) external view returns (uint256) {
    return _userTasks[user].at(index);
  }

  function userTasksContains(address user, uint256 taskId) external view returns (bool) {
    return _userTasks[user].contains(taskId);
  }

  /**
   * @notice creates a new task with the given fields
   * @param target address to perform task on
   * @param gasLimit amount of gas to provide the target contract when
   * performing task
   * @param admin address to cancel task and withdraw remaining funds
   * @param checkData data passed to the contract when checking for task
   */
  function _createTask(
    uint256 id,
    address target,
    uint32 gasLimit,
    address admin,
    uint256 balance,
    bytes memory checkData,
    uint256 startTime
  ) internal whenNotPaused {
    if (!target.isContract()) revert NotAContract();
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > _storage.maxGas)
      revert GasLimitOutsideRange();
    _task[id] = Task({
      target: target,
      executeGas: gasLimit,
      balance: balance,
      admin: admin,
      maxValidBlocknumber: UINT64_MAX,
      lastAutomate: ZERO_ADDRESS,
      amountSpent: 0,
      isPaused: false,
      startTime: startTime
    });
    _expectedBNBBalance += balance;
    _checkData[id] = checkData;
    _taskIDs.add(id);
    _userTasks[admin].add(id);
  }

  /**
   * @dev retrieves feed data for fast gas/eth and eth prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the task clients.
   */
  function _getFeedData() private view returns (uint256 gasWei) {
    uint32 lastFeedSecondsAmt = _storage.lastFeedSecondsAmt;
    bool staleFallback = lastFeedSecondsAmt > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = FAST_GAS_FEED.latestRoundData();
    if ((staleFallback && lastFeedSecondsAmt < block.timestamp - timestamp) || feedValue <= 0) {
      gasWei = _defaultGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    return gasWei;
  }

  /**
   * @dev calculates Native paid for gas spent plus a configure premium percentage
   */
  function _calculatePaymentAmount(uint256 gasLimit, uint256 gasWei)
    private
    view
    returns (uint256 payment)
  {
    uint256 weiForGas = gasWei * (gasLimit + REGISTRY_GAS_OVERHEAD);
    uint256 premium = PPB_BASE + _storage.paymentFee;
    uint256 total = ((weiForGas * (1e9) * (premium)) / 1e18) +
      (uint256(_storage.flatFee) * (1e12));
    return total;
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function _callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev calls the Task target with the performData param passed in by the
   * automate and the exact gas required by the Task
   */
  function _performTaskWithParams(PerformParams memory params)
    private
    nonReentrant
    validTask(params.id)
    returns (bool success)
  {
    Task memory task = _task[params.id];
    _prePerformTask(task, params.from, params.maxNativePayment);

    uint256 gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, params.performData);
    success = _callWithExactGas(params.gasLimit, task.target, callData);
    gasUsed -= gasleft();

    uint256 payment = _calculatePaymentAmount(gasUsed, params.adjustedGasWei);

    uint256 taskBal = _task[params.id].balance;
    if (taskBal >= payment) {
      _task[params.id].balance -= payment;
    } else {
      uint256 remainingAmount = payment - taskBal;
      _task[params.id].balance = 0;
      _userBalance[_task[params.id].admin] -= remainingAmount;
    }
    _task[params.id].amountSpent += payment;
    _task[params.id].lastAutomate = params.from;
    _automateInfo[params.from].balance += payment;

    emit TaskPerformed(params.id, success, params.from, payment, params.performData);
    return success;
  }

  /**
   * @dev ensures all required checks are passed before an task is performed
   */
  function _prePerformTask(
    Task memory task,
    address from,
    uint256 maxNativePayment
  ) private view {
    if (!_automateInfo[from].active) revert OnlyActiveAutomates();
    if (task.balance + _userBalance[task.admin] < maxNativePayment) revert InsufficientFunds();
    if (task.lastAutomate == from) revert AutomatesMustTakeTurns();
  }

  /**
   * @dev adjusts the gas price to min(ceiling, tx.gasprice) or just uses the ceiling if tx.gasprice is disabled
   */
  function _adjustGasPrice(uint256 gasWei, bool useTxGasPrice)
    private
    view
    returns (uint256 adjustedPrice)
  {
    adjustedPrice = gasWei * _storage.gasMultiplier;
    if (useTxGasPrice && tx.gasprice < adjustedPrice) {
      adjustedPrice = tx.gasprice;
    }
  }

  /**
   * @dev generates a PerformParams struct for use in _performTaskWithParams()
   */
  function _generatePerformParams(
    address from,
    uint256 id,
    bytes memory performData,
    bool useTxGasPrice
  ) private view returns (PerformParams memory) {
    uint256 gasLimit = _task[id].executeGas;
    uint256 gasWei = _getFeedData();
    uint256 adjustedGasWei = _adjustGasPrice(gasWei, useTxGasPrice);
    uint256 maxNativePayment = _calculatePaymentAmount(gasLimit, adjustedGasWei);

    return
      PerformParams({
        from: from,
        id: id,
        performData: performData,
        maxNativePayment: maxNativePayment,
        gasLimit: gasLimit,
        adjustedGasWei: adjustedGasWei
      });
  }

  // MODIFIERS

  /**
   * @dev ensures a task is valid
   */
  modifier validTask(uint256 id) {
    if (
      _task[id].maxValidBlocknumber <= block.number ||
      _task[id].startTime > block.timestamp  
    ) revert TaskNotActive();
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the admin of task #id
   */
  modifier onlyTaskAdmin(uint256 id) {
    if (msg.sender != _task[id].admin) revert OnlyByAdmin();
    _;
  }

  /**
   * @dev Reverts if called on a cancelled task
   */
  modifier onlyActiveTask(uint256 id) {
    if (_task[id].maxValidBlocknumber != UINT64_MAX) revert TaskNotActive();
    _;
  }

  /**
   * @dev ensures that burns don't accidentally happen by sending to the zero
   * address
   */
  modifier validRecipient(address to) {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner or registrar.
   */
  modifier onlyOwnerOrregistrar() {
    if (msg.sender != owner() && msg.sender != _registrar) revert OnlyByOwnerOrregistrar();
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner or task admin.
   */
  modifier onlyOwnerOrAdmin(uint256 id) {
    if (msg.sender != owner() && msg.sender != _task[id].admin) revert OnlyOwnerOrAdmin();
    _;
  }
}