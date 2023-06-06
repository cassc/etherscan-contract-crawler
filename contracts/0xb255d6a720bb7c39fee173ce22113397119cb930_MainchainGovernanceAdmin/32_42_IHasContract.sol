// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IHasContract {
  /// @dev Error of set to non-contract.
  error ErrZeroCodeContract();
}