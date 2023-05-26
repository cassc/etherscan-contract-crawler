// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/contracts/abstract/UtilsReady.sol';

interface IKeep3rEscrowParameters {
  function keep3r() external returns (address);
}

abstract contract Keep3rEscrowParameters is UtilsReady, IKeep3rEscrowParameters {
  address public immutable override keep3r;

  constructor(address _keep3r) public UtilsReady() {
    require(address(_keep3r) != address(0), 'Keep3rEscrowParameters::constructor::keep3r-zero-address');
    keep3r = _keep3r;
  }
}