// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../MixedPaymentSplitter.sol';
import '../../../interfaces/IJBDirectory.sol';

/**
 * @notice Creates an instance of MixedPaymentSplitter contract
 */
library MixedPaymentSplitterFactory {
  function createMixedPaymentSplitter(
    string memory _name,
    address[] memory _payees,
    uint256[] memory _projects,
    uint256[] memory _shares,
    IJBDirectory _jbxDirectory,
    address _owner
  ) public returns (address) {
    MixedPaymentSplitter s = new MixedPaymentSplitter(
      _name,
      _payees,
      _projects,
      _shares,
      _jbxDirectory,
      _owner
    );

    return address(s);
  }
}