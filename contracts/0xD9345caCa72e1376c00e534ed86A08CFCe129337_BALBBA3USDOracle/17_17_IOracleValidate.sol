// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IOracleValidate {
  /// @notice Check the oracle (re-entrancy)
  function check() external;
}