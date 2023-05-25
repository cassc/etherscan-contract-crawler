// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IReentrancyGuard} from "./interfaces/IReentrancyGuard.sol";

/**
 * @title PackableReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 *         The only difference between this contract and ReentrancyGuard
 *         is that _status is uint8 instead of uint256 so that it can be
 *         packed with other contracts' storage variables.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract PackableReentrancyGuard is IReentrancyGuard {
    uint8 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}