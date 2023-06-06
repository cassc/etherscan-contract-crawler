// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import '../Vault.sol';
import '../interfaces/IMStable.sol';
import './NexusMock.sol';

contract MStableLendMock is Vault {
  constructor(address _reserve, address _nexus) public Vault(_reserve, _nexus) {}

  function updateContracts() public {
    address savingsManager = IMStable(nexusGovernance).getModule(keccak256('SavingsManager'));
    savingsContract = IMStable(savingsManager).savingsContracts(reserve);
  }
}