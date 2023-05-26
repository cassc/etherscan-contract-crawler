// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./Governable.sol";
import "../interfaces/IOnlyEOA.sol";

abstract contract OnlyEOA is IOnlyEOA, Governable {
    /// @inheritdoc IOnlyEOA
    bool public onlyEOA;

    // Methods

    /// @inheritdoc IOnlyEOA
    function setOnlyEOA(bool _onlyEOA) external onlyGovernor {
        _setOnlyEOA(_onlyEOA);
    }

    // Internals

    function _setOnlyEOA(bool _onlyEOA) internal {
        onlyEOA = _onlyEOA;
        emit OnlyEOASet(_onlyEOA);
    }

    function _validateEOA(address _caller) internal view {
        // solhint-disable-next-line avoid-tx-origin
        if (_caller != tx.origin) revert OnlyEOA();
    }
}