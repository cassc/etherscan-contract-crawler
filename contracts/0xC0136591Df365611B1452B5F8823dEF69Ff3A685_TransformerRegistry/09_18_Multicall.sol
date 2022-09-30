// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '../../interfaces/utils/IMulticall.sol';

/**
 * @dev Adding this contract will enable batching calls. This is basically the same as Open Zeppelin's
 *      Multicall contract, but we have made it payable. Any contract that uses this Multicall version
 *      should be very careful when using msg.value.
 *      For more context, read: https://github.com/Uniswap/v3-periphery/issues/52
 */
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
    return results;
  }
}