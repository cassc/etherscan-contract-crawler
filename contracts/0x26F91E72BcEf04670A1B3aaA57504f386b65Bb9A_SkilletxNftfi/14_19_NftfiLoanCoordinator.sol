// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

import "./interfaces/ILoanCoordinator.sol";

import "./NftfiAddressProvider.sol";

import "./structs/NftfiStructs.sol";

contract NftfiLoanCoordinator is NftfiAddressProvider {

  function getNewLoanId() public view returns (uint32 loanId) {
    ILoanCoordinator coordinator = ILoanCoordinator(loanCoordinatorAddress);
    loanId = coordinator.totalNumLoans();
  }
}