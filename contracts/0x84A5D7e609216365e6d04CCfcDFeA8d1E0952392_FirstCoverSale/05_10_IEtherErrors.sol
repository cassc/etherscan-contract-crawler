// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IEtherErrors {
  /**
  * @dev Thrown when an incorrect amount of eth is being sent for a payable operation.
  * 
  * @param amountReceived the amount the contract received
  * @param amountExpected the actual amount the contract expected to receive
  */
  error ETHER_INCORRECT_PRICE(uint256 amountReceived, uint256 amountExpected);
  /**
  * @dev Thrown when trying to withdraw from the contract with no balance.
  */
  error ETHER_NO_BALANCE();
  /**
  * @dev Thrown when contract fails to send ether to recipient.
  * 
  * @param to the recipient of the ether
  * @param amount the amount of ether being sent
  */
  error ETHER_TRANSFER_FAIL(address to, uint256 amount);
}