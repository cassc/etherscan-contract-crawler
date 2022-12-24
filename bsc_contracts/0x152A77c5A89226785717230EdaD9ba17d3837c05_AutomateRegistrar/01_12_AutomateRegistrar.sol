// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { IReceiver } from "./interfaces/IReceiver.sol";
import { ConfirmedOwner } from "./ConfirmedOwner.sol";

import { IVersion } from "./interfaces/IVersion.sol";
import { IAutomateRegistryBase } from "./interfaces/IAutomateRegistry.sol";

/**
 * @notice Contract to accept requests for task registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register task and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registertask` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract AutomateRegistrar is 
IVersion,
IReceiver,
OwnableUpgradeable,
PausableUpgradeable
{
  /**
   * DISABLED: No auto approvals, all new tasks should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new tasks subject to max allowed.
   */
  enum EAutoApprove {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  mapping(bytes32 => PendingRequest) private _pendingRequests;

  string public constant override version = "AutomateRegistrar 1.0.0";

  struct Config {
    EAutoApprove autoApproveConfig;
    uint32 autoApproveMaxAllowed;
    uint32 approvedCount;
    IAutomateRegistryBase automateRegistry;
    uint96 minBNBAmount;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  Config private _config;
  // Only applicable if _config.configType is ENABLED_SENDER_ALLOWLIST
  mapping(address => bool) private _autoApproveToSenders;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed taskContract,
    uint32 gasLimit,
    address adminAddress,
    bytes checkData,
    uint96 amount,
    uint8 indexed source,
    uint256 startTime
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed taskId, uint256 startTime);

  event RegistrationRejected(bytes32 indexed hash);

  event AutoApproveToSenderSet(address indexed senderAddress, bool allowed);

  event ConfigChanged(
    EAutoApprove autoApproveConfig,
    uint32 autoApproveMaxAllowed,
    address automateRegistry,
    uint96 minBNBAmount
  );

  error InvalidAdmin();
  error NoRequest();
  error HashMismatch();
  error OnlyAdminOrOwner();
  error NotEnoughFunds();
  error RegistrationRequestFailed();
  error AmountMismatch();
  error SenderMismatch();
  error OnlyThisContract();
  error FunctionNotAccepted();
  error FailedTransfer(address to);
  error InvalidData();

  /*
   * @param autoApproveConfig setting for auto-approve registrations
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param automateRegistry keeper registry address
   * @param minBNBAmount minimum BNB that new registrations should fund their task with
   */
  function initialize(
    EAutoApprove autoApproveConfig,
    uint16 autoApproveMaxAllowed,
    address automateRegistry,
    uint96 minBNBAmount
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    setRegistrationConfig(autoApproveConfig, autoApproveMaxAllowed, automateRegistry, minBNBAmount);
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferWithData
   * @param name string of the task to be registered
   * @param encryptedEmail email address of task contact
   * @param taskContract address to perform task on
   * @param gasLimit amount of gas to provide the target contract when performing task
   * @param adminAddress address to cancel task and withdraw remaining funds
   * @param checkData data passed to the contract when checking for task
   * @param amount quantity of Native task is funded with (specified in Juels)
   * @param source application sending this request
   * @param sender address of the sender making the request
   */
  function register(
    string memory name,
    bytes memory encryptedEmail,
    address taskContract,
    uint32 gasLimit,
    address adminAddress,
    bytes memory checkData,
    uint96 amount,
    uint8 source,
    address sender,
    uint256 startTime
  ) external onlyThisContract {
    if (adminAddress == address(0)) {
      revert InvalidAdmin();
    }
    bytes32 hash = keccak256(abi.encode(taskContract, gasLimit, adminAddress, checkData));

    emit RegistrationRequested(
      hash,
      name,
      encryptedEmail,
      taskContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source,
      startTime
    );

    Config memory config = _config;
    if (_autoApproveIfNecessary(config, sender)) {
      _config.approvedCount++;

      _approve(name, taskContract, gasLimit, adminAddress, checkData, amount, hash, startTime);
    } else {
      uint96 newBalance = _pendingRequests[hash].balance + amount;
      _pendingRequests[hash] = PendingRequest({ admin: adminAddress, balance: newBalance });
    }
  }

  /**
   * @dev register task on AutomateRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address taskContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes32 hash,
    uint256 startTime
  ) external onlyOwner {
    PendingRequest memory request = _pendingRequests[hash];
    if (request.admin == address(0)) {
      revert NoRequest();
    }
    bytes32 expectedHash = keccak256(abi.encode(taskContract, gasLimit, adminAddress, checkData));
    if (hash != expectedHash) {
      revert HashMismatch();
    }
    delete _pendingRequests[hash];
    _approve(name, taskContract, gasLimit, adminAddress, checkData, request.balance, hash, startTime);
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the msg.sender
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = _pendingRequests[hash];
    if (!(msg.sender == request.admin || msg.sender == owner())) {
      revert OnlyAdminOrOwner();
    }
    if (request.admin == address(0)) {
      revert NoRequest();
    }
    delete _pendingRequests[hash];
    bool success = payable(msg.sender).send(request.balance);
    if (!success) {
      revert FailedTransfer(msg.sender);
    }
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set if registration requests should be sent directly to the Automate Registry
   * @param autoApproveConfig setting for auto-approve registrations
   *                   note: autoApproveAllowedSenders list persists across config changes irrespective of type
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param automateRegistry new keeper registry address
   * @param minBNBAmount minimum BNB that new registrations should fund their task with
   */
  function setRegistrationConfig(
    EAutoApprove autoApproveConfig,
    uint16 autoApproveMaxAllowed,
    address automateRegistry,
    uint96 minBNBAmount
  ) public onlyOwner {
    uint32 approvedCount = _config.approvedCount;
    _config = Config({
      autoApproveConfig: autoApproveConfig,
      autoApproveMaxAllowed: autoApproveMaxAllowed,
      approvedCount: approvedCount,
      minBNBAmount: minBNBAmount,
      automateRegistry: IAutomateRegistryBase(automateRegistry)
    });

    emit ConfigChanged(autoApproveConfig, autoApproveMaxAllowed, automateRegistry, minBNBAmount);
  }

  /**
   * @notice owner calls this function to set allowlist status for senderAddress
   * @param senderAddress senderAddress to set the allowlist status for
   * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
   */
  function setAutoApproveToSender(address senderAddress, bool allowed) external onlyOwner {
    _autoApproveToSenders[senderAddress] = allowed;

    emit AutoApproveToSenderSet(senderAddress, allowed);
  }

  /**
   * @notice read the allowlist status of senderAddress
   * @param senderAddress address to read the allowlist status for
   */
  function getAutoApproveToSender(address senderAddress) external view returns (bool) {
    return _autoApproveToSenders[senderAddress];
  }

  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
      EAutoApprove autoApproveConfig,
      uint32 autoApproveMaxAllowed,
      uint32 approvedCount,
      address automateRegistry,
      uint256 minBNBAmount
    )
  {
    Config memory config = _config;
    return (
      config.autoApproveConfig,
      config.autoApproveMaxAllowed,
      config.approvedCount,
      address(config.automateRegistry),
      config.minBNBAmount
    );
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = _pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when Native is sent to the contract via `transferWithData`
   * @param data Payload of the transaction
   */
  function transferWithData(bytes memory data)
    external
    payable
    override
    whenNotPaused
    acceptedFunction(data)
    isActualAmount(data)
    isActualSender(data)
    returns (bool)
  {
    address actual;
    assembly {
      actual := mload(add(data, 292))
    }
    if (data.length < 292) revert InvalidData();
    if (msg.value < _config.minBNBAmount) {
      revert NotEnoughFunds();
    }
    (bool success, ) = address(this).call(data);
    // calls register
    if (!success) {
      revert RegistrationRequestFailed();
    }
    return true;
  }

    /**
   * @notice pauses the contract
   */
  function pause() external onlyOwner whenNotPaused {
    _pause();
  }

  /**
   * @notice unpauses the contract
   */
  function unpause() external onlyOwner whenPaused {
    _unpause();
  }

  //PRIVATE

  /**
   * @dev register task on AutomateRegistry contract and emit RegistrationApproved event
   */
  function _approve(
    string memory name,
    address taskContract,
    uint32 gasLimit,
    address adminAddress,
    bytes memory checkData,
    uint96 amount,
    bytes32 hash,
    uint256 startTime
  ) private {
    IAutomateRegistryBase automateRegistry = _config.automateRegistry;

    // register task
    uint256 taskId = automateRegistry.registerTask(taskContract, gasLimit, adminAddress, checkData, startTime);
    // fund task
    bool success = automateRegistry.transferWithData{ value: amount }(abi.encode(taskId));
    if (!success) {
      revert FailedTransfer(address(automateRegistry));
    }
    emit RegistrationApproved(hash, name, taskId, startTime);
  }

  /**
   * @dev verify sender allowlist if needed and check max limit
   */
  function _autoApproveIfNecessary(Config memory config, address sender) private returns (bool) {
    if (config.autoApproveConfig == EAutoApprove.DISABLED) {
      return false;
    }
    if (
      config.autoApproveConfig == EAutoApprove.ENABLED_SENDER_ALLOWLIST &&
      (!_autoApproveToSenders[sender])
    ) {
      return false;
    }
    if (config.approvedCount < config.autoApproveMaxAllowed) {
      return true;
    }
    return false;
  }

  //MODIFIERS

  /**
   * @dev Reverts if not sent from the current contract contract
   */
  modifier onlyThisContract() {
    if (msg.sender != address(this)) {
      revert OnlyThisContract();
    }
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param data The data payload of the request
   */
  modifier acceptedFunction(bytes memory data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(data, 32)) // First 32 bytes contain length of data
    }
    if (funcSelector != REGISTER_REQUEST_SELECTOR) {
      revert FunctionNotAccepted();
    }
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param data bytes
   */
  modifier isActualAmount(bytes memory data) {
    uint256 actual;
    assembly {
      actual := mload(add(data, 228))
    }
    if (msg.value != actual) {
      revert AmountMismatch();
    }
    _;
  }

  /**
   * @dev Reverts if the actual sender address does not match the expected sender address
   * @param data bytes
   */
  modifier isActualSender(bytes memory data) {
    address actual;
    assembly {
      actual := mload(add(data, 292))
    }
    if (msg.sender != actual) {
      revert SenderMismatch();
    }
    _;
  }
}