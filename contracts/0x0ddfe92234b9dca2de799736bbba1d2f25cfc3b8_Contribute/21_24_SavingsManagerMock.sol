// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './SavingsContractMock.sol';

contract SavingsManagerMock {
  SavingsContractMock SC;

  constructor(address _reserve) public {
    SC = new SavingsContractMock(_reserve);
  }

  function savingsContracts(address) external view returns (address) {
    return address(SC);
  }
}