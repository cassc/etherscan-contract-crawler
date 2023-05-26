// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {DepositItem} from "../lib/DepositStructs.sol";

interface DepositInterface {
  /**
   * @dev Emit an event when the recipient is updated.
   *
   * @param from The old recipient
   * @param to The new recipient
   */
  event UpdateRecipient(address indexed from, address indexed to);

  /**
   * @dev Emit an event when the deposit is enabled.
   */
  event EnableDeposit();

  /**
   * @dev Emit an event when the deposit is disabled.
   */
  event DisableDeposit();

  /**
   * @dev Emit an event when the batch transfer is successful.
   *
   * @param requestId The request id from client
   */
  event BulkDeposit(uint256 indexed requestId);

  /**
   * @notice Update recipient
   *
   * @param recipient  The new recipient
   */
  function updateRecipient(address recipient) external;

  /**
   * @notice Enable deposit
   */
  function enableDeposit() external;

  /**
   * @notice Disable deposit
   */
  function disableDeposit() external;

  /**
   * @notice Deposit multiple items.
   *
   * @param items The items to transfer.
   * @param requestId  The request id from client.
   */
  function bulkDeposit(DepositItem[] calldata items, uint256 requestId) external;
}