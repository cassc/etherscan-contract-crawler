// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/interfaces/keep3r/IKeep3rV1.sol';

interface IKeep3rLiquidityManagerParameters {
  event Keep3rV1Set(address _keep3rV1);

  function keep3rV1() external view returns (address);
}

abstract contract Keep3rLiquidityManagerParameters is IKeep3rLiquidityManagerParameters {
  address public override keep3rV1;

  constructor(address _keep3rV1) public {
    _setKeep3rV1(_keep3rV1);
  }

  function _setKeep3rV1(address _keep3rV1) internal {
    require(_keep3rV1 != address(0), 'Keep3rLiquidityManager::zero-address');
    keep3rV1 = _keep3rV1;
    emit Keep3rV1Set(_keep3rV1);
  }
}