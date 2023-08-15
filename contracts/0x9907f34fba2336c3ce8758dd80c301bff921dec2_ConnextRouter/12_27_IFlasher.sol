// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFlasher
 * @author Fujidao Labs
 * @notice Defines the interface for all flashloan providers.
 */

interface IFlasher {
  /**
   * @notice Initiates a flashloan a this provider.
   * @param asset address to be flashloaned.
   * @param amount of `asset` to be flashloaned.
   * @param requestor address to which flashloan will be facilitated.
   * @param requestorCalldata encoded args with selector that will be OPCODE-CALL'ed to `requestor`.
   * @dev To encode `params` see examples:
   * • solidity:
   *   > abi.encodeWithSelector(contract.transferFrom.selector, from, to, amount);
   * • ethersJS:
   *   > contract.interface.encodeFunctionData("transferFrom", [from, to, amount]);
   * • foundry cast:
   *   > cast calldata "transferFrom(address,address,uint256)" from, to, amount
   *
   * Requirements:
   * - MUST implement `_checkAndSetEntryPoint()`
   */
  function initiateFlashloan(
    address asset,
    uint256 amount,
    address requestor,
    bytes memory requestorCalldata
  )
    external;

  /**
   * @notice Returns the address from which flashloan for `asset` is sourced.
   * @param asset intended to be flashloaned.
   * @dev Override at flashloan provider implementation as required.
   * Some protocol implementations source flashloans from different contracts
   * depending on `asset`.
   */
  function getFlashloanSourceAddr(address asset) external view returns (address callAddr);

  /**
   * @notice Returns the expected flashloan fee for `amount`
   * of this flashloan provider.
   * @param asset to be flashloaned
   * @param amount of flashloan
   */
  function computeFlashloanFee(address asset, uint256 amount) external view returns (uint256 fee);
}