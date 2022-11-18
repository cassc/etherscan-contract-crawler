// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @title ReentrancyGuarded
 * @author Wyvern Protocol Developers
 */
contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}