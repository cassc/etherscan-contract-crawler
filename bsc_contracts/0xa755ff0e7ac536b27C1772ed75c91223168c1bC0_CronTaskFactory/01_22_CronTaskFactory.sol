// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { CronTask } from "../tasks/CronTask.sol";
import { CronTaskDelegate } from "../tasks/CronTaskDelegate.sol";
import { ConfirmedOwner } from "../ConfirmedOwner.sol";
import { Spec, Cron as CronExternal } from "../libraries/external/Cron.sol";

/**
 * @title The CronTaskFactory contract
 * @notice This contract serves as a delegate for all instances of CronTask. Those contracts
 * delegate their checkTask calls onto this contract. Utilizing this pattern reduces the size
 * of the CronTask contracts.
 */
contract CronTaskFactory is
OwnableUpgradeable,
PausableUpgradeable
 {
  event NewCronTaskCreated(address task, address owner);
  event CronDelegateChanged(address cronDelegate);

  address private s_cronDelegate;
  uint256 public s_maxJobs;

  function initialize(address cronTaskDelegate, uint256 maxJobs) public initializer {
    __Ownable_init();
    __Pausable_init();
    s_maxJobs = maxJobs;
    s_cronDelegate = cronTaskDelegate;
  }

  /**
   * @notice Creates a new CronTask contract, with msg.sender as the owner
   */
  function newCronTask() external whenNotPaused {
    newCronTaskWithJob(bytes(""));
  }

  /**
   * @notice Creates a new CronTask contract, with msg.sender as the owner, and registers a cron job
   */
  function newCronTaskWithJob(bytes memory encodedJob) public whenNotPaused {
    emit NewCronTaskCreated(
      address(new CronTask(msg.sender, s_cronDelegate, s_maxJobs, encodedJob)),
      msg.sender
    );
  }

  /**
   * @notice Sets the max job limit on new cron tasks
   */
  function setMaxJobs(uint256 maxJobs) external onlyOwner {
    s_maxJobs = maxJobs;
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

  function setCronDelegate(address cronDelegate) external onlyOwner {
    s_cronDelegate = cronDelegate;
    emit CronDelegateChanged(cronDelegate);
  }

  /**
   * @notice Gets the address of the delegate contract
   * @return the address of the delegate contract
   */
  function cronDelegateAddress() external view returns (address) {
    return s_cronDelegate;
  }

  /**
   * @notice Converts a cron string to a Spec, validates the spec, and encodes the spec.
   * This should only be called off-chain, as it is gas expensive!
   * @param cronString the cron string to convert and encode
   * @return the abi encoding of the Spec struct representing the cron string
   */
  function encodeCronString(string memory cronString) external pure returns (bytes memory) {
    return CronExternal.toEncodedSpec(cronString);
  }

  /**
   * @notice Converts, validates, and encodes a full cron spec. This payload is then passed to newCronTaskWithJob.
   * @param target the destination contract of a cron job
   * @param handler the function signature on the target contract to call
   * @param cronString the cron string to convert and encode
   * @return the abi encoding of the entire cron job
   */
  function encodeCronJob(
    address target,
    bytes memory handler,
    string memory cronString
  ) external pure returns (bytes memory) {
    Spec memory spec = CronExternal.toSpec(cronString);
    return abi.encode(target, handler, spec);
  }
}