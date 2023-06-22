// SPDX-License-Identifier: GPL-3.0

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

pragma solidity ^0.8.19;

/// This is a base contract to aid in adding incentives to your protocol
abstract contract Motivator {
  /// Emitted when a caller receives a gas refund with tip
  event GasRefundWithTip(address indexed to, uint256 refund, uint256 tip);

  /// Base gas to refund
  uint256 public constant REFUND_BASE_GAS = 36000;

  /// Max priority fee used for refunds
  uint256 public constant MAX_REFUND_PRIORITY_FEE = 1 gwei;

  /// Max gas units that will be refunded
  uint256 public constant MAX_REFUND_GAS_USED = 200_000;

  /// Refunds gas spent on a transaction and includes a tip
  function _gasRefundWithTipAndCap(
    uint256 _startGas,
    uint256 _cap,
    uint256 _maxBaseFee,
    uint256 _tip
  ) internal view returns (uint256) {
    unchecked {
      uint256 balance = address(this).balance;
      if (balance == 0) {
        return 0;
      }

      uint256 basefee = min(block.basefee, _maxBaseFee);
      uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
      uint256 gasUsed = min(_startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
      uint256 refundAmount = min((gasPrice * gasUsed) + _tip, balance);
      return min(_cap, refundAmount);
    }
  }

  /// Returns the min of two integers
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}