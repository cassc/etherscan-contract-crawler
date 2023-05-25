// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../Recoverable.sol";

contract RecoverableHarness is Recoverable {
  constructor(address governance) {
    _setupRole(RECOVER_ROLE, governance);
  }

  receive() external payable {
    // Blindly accept ETH.
  }
}