// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/DepositInterface.sol";
import "./lib/ConfirmedOwner.sol";
import {DepositItem} from "./lib/DepositStructs.sol";

/**
 * @title DepositHelper
 * @notice DepositHelper is a utility contract for transferring
 *         ERC721 items in bulk to a fixed recipient.
 */
contract Deposit is DepositInterface, ConfirmedOwner {
  // Deposit enabled status
  bool public isEnabled;
  // recipient
  address public recipient;

  /**
   * @dev Reverts if the deposit is not enabled
   */
  modifier checkEnabled() {
    require(isEnabled, "Deposit suspended");
    _;
  }

  /**
   * @dev Set the supplied recipient.
   *
   *
   * @param _recipient The recipient address, used to receive
   *                          ERC721 tokens.
   * @param _owner The contract owner address.
   */
  constructor(address _recipient, address _owner) ConfirmedOwner(_owner) {
    recipient = _recipient;
    isEnabled = true;
  }

  /**
   * @dev Update recipient
   * @param _recipient  The new recipient.
   */
  function updateRecipient(address _recipient) external override onlyOwner {
    require(_recipient != recipient, "Not changed");
    require(_recipient != address(0), "Cannot set recipient to zero");
    address oldRecipient = recipient;
    recipient = _recipient;
    emit UpdateRecipient(oldRecipient, recipient);
  }

  /**
   * @notice Enable deposit
   */
  function enableDeposit() external override onlyOwner {
    if (!isEnabled) {
      isEnabled = true;

      emit EnableDeposit();
    }
  }

  /**
   * @notice Disable deposit
   */
  function disableDeposit() external override onlyOwner {
    if (isEnabled) {
      isEnabled = false;

      emit DisableDeposit();
    }
  }

  /**
   * @notice Transfer multiple ERC721 items to
   *         specified recipients.
   *
   * @param items      The items to transfer to an intended recipient.
   * @param requestId An optional request id from client.
   */
  function bulkDeposit(DepositItem[] calldata items, uint256 requestId) external override checkEnabled {
    require(items.length > 0, "Deposit items cannot be empty");
    // Perform transfers.
    // Iterate over each item in the items to perform ERC721 transfer.
    for (uint256 i = 0; i < items.length; ++i) {
      // Retrieve the item from the transfers.
      DepositItem calldata item = items[i];
      // Transfer ERC721 token.
      IERC721(item.token).safeTransferFrom(msg.sender, recipient, item.identifier);
    }

    // emit bulk deposit event
    emit BulkDeposit(requestId);
  }
}