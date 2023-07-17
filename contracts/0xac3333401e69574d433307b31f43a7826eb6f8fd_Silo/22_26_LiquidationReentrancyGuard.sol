// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev This is cloned solution of @openzeppelin/contracts/security/ReentrancyGuard.sol
abstract contract LiquidationReentrancyGuard {
    error LiquidationReentrancyCall();

    uint256 private constant _LIQUIDATION_NOT_ENTERED = 1;
    uint256 private constant _LIQUIDATION_ENTERED = 2;

    uint256 private _liquidationStatus;

    modifier liquidationNonReentrant() {
        if (_liquidationStatus == _LIQUIDATION_ENTERED) {
            revert LiquidationReentrancyCall();
        }

        _liquidationStatus = _LIQUIDATION_ENTERED;

        _;

        _liquidationStatus = _LIQUIDATION_NOT_ENTERED;
    }

    constructor() {
        _liquidationStatus = _LIQUIDATION_NOT_ENTERED;
    }
}