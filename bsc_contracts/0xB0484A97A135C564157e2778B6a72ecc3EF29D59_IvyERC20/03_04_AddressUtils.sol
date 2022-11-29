// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @author Basil Gorin
 */
library AddressUtils {

  /**
   * @notice Checks if the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *      as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    // a variable to load `extcodesize` to
    uint256 size = 0;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
    // TODO: Check this again before the Serenity release, because all addresses will be contracts.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // retrieve the size of the code at address `addr`
      size := extcodesize(addr)
    }

    // positive size indicates a smart contract address
    return size > 0;
  }

}