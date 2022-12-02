// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IReentrancyGuardErrors} from "../interfaces/utils/IReentrancyGuardErrors.sol";

abstract contract ReentrancyGuard is IReentrancyGuardErrors {

    uint256 private constant _LOCKED = 1;
    uint256 private constant _UNLOCKED = 2;

    uint256 internal _locked = _UNLOCKED;

    modifier nonReentrant() {
        if (_locked != _UNLOCKED) {
            revert FunctionReentrant();
        }
        _locked = _LOCKED;
        _;
        _locked = _UNLOCKED;
    }

}