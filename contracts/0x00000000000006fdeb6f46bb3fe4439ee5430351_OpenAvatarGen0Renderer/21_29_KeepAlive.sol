// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title KeepAlive
 * @dev KeepAlive is a contract designed to maintain its onchain presence in
 * case of state expiration by using payable receive() and fallback() functions,
 * while allow the owner to still withdraw funds.
 * fallback():
 *   - Default function that gets executed when no other function in the contract
 *     matches the provided function signature, or when the contract receives
 *     Ether along with data
 *   - Can be payable or non-payable
 *   - Must be marked external
 * receive():
 *   - Introduced in Solidity 0.6.0
 *   - Special function that is executed when a contract receives Ether without
 *     any data
 *   - Must be payable
 *   - Must be marked external
 *   - Makes it easier to differentiate between intended Ether transfers and
 *     other function calls
 */
contract KeepAlive is Ownable {
  /**
   * @notice Fallback function.
   * @dev fallback():
   *  - Default function that gets executed when no other function in the contract
   *    matches the provided function signature, or when the contract receives
   *    Ether along with data
   *  - Can be payable or non-payable
   *  - Must be marked external
   */
  // solhint-disable-next-line no-empty-blocks
  fallback() external payable {}

  /**
   * @notice Receive funds.
   * @dev receive():
   *   - Introduced in Solidity 0.6.0
   *   - Special function that is executed when a contract receives Ether without
   *     any data
   *   - Must be payable
   *   - Must be marked external
   *   - Makes it easier to differentiate between intended Ether transfers and
   *     other function calls
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Withdraw funds from the contract.
   */
  function withdraw(uint amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }
}