// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyGuard
 * @author 0xth0mas (Layerr)
 * @notice Simple reentrancy guard to prevent callers from re-entering the LayerrMinter mint functions
 */
contract ReentrancyGuard {
    uint256 private _reentrancyGuard = 1;
    error ReentrancyProhibited();

    modifier NonReentrant() {
        if (_reentrancyGuard > 1) {
            revert ReentrancyProhibited();
        }
        _reentrancyGuard = 2;
        _;
        _reentrancyGuard = 1;
    }
}