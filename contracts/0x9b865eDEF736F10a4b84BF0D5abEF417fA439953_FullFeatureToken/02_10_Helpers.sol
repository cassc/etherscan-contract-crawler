// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

library Helpers {
  /// @notice raised when an address is zero
  error NonZeroAddress(address addr);
  /// @notice raised when payment fails
  error PaymentFailed(address to, uint256 amount);

  /**
   * @notice Helper function to check if an address is a zero address
   * @param addr - address to check
   */
  function validateAddress(address addr) internal pure {
    if (addr == address(0x0)) {
      revert NonZeroAddress(addr);
    }
  }

  /**
   * @notice method to pay a specific address with a specific amount
   * @dev inspired from https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol
   * @param to - the address to pay
   * @param amount - the amount to pay
   */
  function safeTransferETH(address to, uint256 amount) internal {
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!success) {
      revert PaymentFailed(to, amount);
    }
  }
}