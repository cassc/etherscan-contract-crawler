// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import '../../interfaces/utils/IOnlyEOA.sol';
import './Governable.sol';

abstract contract OnlyEOA is IOnlyEOA, Governable {
  /// @inheritdoc IOnlyEOA
  bool public onlyEOA;

  // methods

  /// @inheritdoc IOnlyEOA
  function setOnlyEOA(bool _onlyEOA) external onlyGovernor {
    _setOnlyEOA(_onlyEOA);
  }

  // internals

  function _setOnlyEOA(bool _onlyEOA) internal {
    onlyEOA = _onlyEOA;
    emit OnlyEOASet(_onlyEOA);
  }

  function _validateEOA(address _caller) internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (_caller != tx.origin) revert OnlyEOA();
  }
}