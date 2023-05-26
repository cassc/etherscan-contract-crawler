// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@lbertenasco/contract-utils/interfaces/utils/IGovernable.sol';
import '@lbertenasco/contract-utils/interfaces/utils/ICollectableDust.sol';

import '../escrow/Keep3rEscrow.sol';

interface IKeep3rLiquidityManagerEscrowsHandler {
  event Escrow1Set(address _escrow1);

  event Escrow2Set(address _escrow2);

  function escrow1() external view returns (address _escrow1);

  function escrow2() external view returns (address _escrow2);

  function isValidEscrow(address _escrow) external view returns (bool);

  function addLiquidityToJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job
  ) external returns (uint256 _amount);

  function setPendingGovernorOnEscrow(address _escrow, address _pendingGovernor) external;

  function acceptGovernorOnEscrow(address _escrow) external;

  function sendDustOnEscrow(
    address _escrow,
    address _to,
    address _token,
    uint256 _amount
  ) external;
}

abstract contract Keep3rLiquidityManagerEscrowsHandler is IKeep3rLiquidityManagerEscrowsHandler {
  address public immutable override escrow1;
  address public immutable override escrow2;

  constructor(address _escrow1, address _escrow2) public {
    require(_escrow1 != address(0), 'Keep3rLiquidityManager::zero-address');
    require(_escrow2 != address(0), 'Keep3rLiquidityManager::zero-address');
    escrow1 = _escrow1;
    escrow2 = _escrow2;
  }

  modifier _assertIsValidEscrow(address _escrow) {
    require(isValidEscrow(_escrow), 'Keep3rLiquidityManager::invalid-escrow');
    _;
  }

  function isValidEscrow(address _escrow) public view override returns (bool) {
    return _escrow == escrow1 || _escrow == escrow2;
  }

  function _addLiquidityToJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).addLiquidityToJob(_liquidity, _job, _amount);
  }

  function _applyCreditToJob(
    address _escrow,
    address _liquidity,
    address _job
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).applyCreditToJob(address(_escrow), _liquidity, _job);
  }

  function _unbondLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    IKeep3rEscrow(_escrow).unbondLiquidityFromJob(_liquidity, _job, _amount);
  }

  function _removeLiquidityFromJob(
    address _escrow,
    address _liquidity,
    address _job
  ) internal _assertIsValidEscrow(_escrow) returns (uint256 _amount) {
    return IKeep3rEscrow(_escrow).removeLiquidityFromJob(_liquidity, _job);
  }

  function _setPendingGovernorOnEscrow(address _escrow, address _pendingGovernor) internal _assertIsValidEscrow(_escrow) {
    IGovernable(_escrow).setPendingGovernor(_pendingGovernor);
  }

  function _acceptGovernorOnEscrow(address _escrow) internal _assertIsValidEscrow(_escrow) {
    IGovernable(_escrow).acceptGovernor();
  }

  function _sendDustOnEscrow(
    address _escrow,
    address _to,
    address _token,
    uint256 _amount
  ) internal _assertIsValidEscrow(_escrow) {
    ICollectableDust(_escrow).sendDust(_to, _token, _amount);
  }
}