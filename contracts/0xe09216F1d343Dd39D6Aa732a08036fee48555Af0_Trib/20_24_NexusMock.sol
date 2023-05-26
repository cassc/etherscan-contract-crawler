// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './SavingsManagerMock.sol';
import './SavingsContractMock.sol';

contract NexusMock {
  SavingsManagerMock public SM;

  constructor(address _reserve) public {
    SM = new SavingsManagerMock(_reserve);
  }

  function getModule(bytes32 value) external view returns (address) {
    bytes32 val = value;
    val;
    return address(SM);
  }

  function createNewSM(address _reserve) public {
    SM = new SavingsManagerMock(_reserve);
  }
}