// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../storage/GovernableStorage.sol";
import "../interfaces/IGovernable.sol";

contract Governable is GovernableStorage, IGovernable {
  function _initialize(address initialGovernance) internal virtual {
    _governance = initialGovernance;
  }

  function governance() external view override returns (address) {
    return _governance;
  }

  modifier onlyGovernance() {
    if (msg.sender != _governance) {
      revert NotGovernance();
    }
    _;
  }

  function setGovernance(address newGovernance) public onlyGovernance {
    emit GovernanceTransferred(_governance, newGovernance);
    _governance = newGovernance;
  }
}