// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IReceiver } from "./IReceiver.sol";

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentFee payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFee flat fee paid to oracles for performing tasks,
 * priced in MicroBNB; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerAutomate number of blocks each oracle has during their turn to
 * perform task before it will be the next keeper's turn to submit
 * @member gasLimit gas limit when checking for task
 * @member lastFeedSecondsAmt number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minTaskSpend minimum BNB that an task must spend before cancelling
 * @member maxGas max executeGas allowed for an task on this registry
 * @member defaultGasPrice gas price used if the gas price feed is stale
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentFee;
  uint32 flatFee; 
  uint24 blockCountPerAutomate;
  uint32 gasLimit;
  uint24 lastFeedSecondsAmt;
  uint16 gasMultiplier;
  uint256 minTaskSpend;
  uint32 maxGas;
  uint256 defaultGasPrice;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerBNBBalance withdrawable balance of BNB by contract owner
 * @member expectedBNBBalance the expected balance of BNB of the registry
 * @member numTasks total number of tasks on the registry
 */
struct State {
  uint32 nonce;
  uint256 ownerBNBBalance;
  uint256 expectedBNBBalance;
  uint256 numTasks;
}

interface IAutomateRegistryBase is IReceiver {
  function registerTask(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    uint256 startTime
  ) external returns (uint256 id);

  function performTask(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelTask(uint256 id) external;

  function addFunds(uint256 id) external payable;

  function setTaskGasLimit(uint256 id, uint32 gasLimit) external;

  function getTask(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint256 balance,
      address lastAutomater,
      address admin,
      uint64 maxValidBlocknumber,
      uint256 amountSpent,
      bool isPaused,
      uint256 startTime
    );

  function getActiveTaskIDs(uint256 startIndex, uint256 maxCount)
    external
    view
    returns (uint256[] memory);

  function getAutomateInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint256 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface IAutomateRegistry is IAutomateRegistryBase {
  function checkTask(uint256 taskId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxBNBPayment,
      uint256 gasLimit,
      int256 gasWei
    );
}

interface IAutomateRegistryExecutable is IAutomateRegistryBase {
  function checkTask(uint256 taskId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxBNBPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei
    );
}