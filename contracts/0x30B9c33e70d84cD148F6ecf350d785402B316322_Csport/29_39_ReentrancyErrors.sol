// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ReentrancyErrors
 * @author Csport dev
 * @notice ReentrancyErrors contains errors related to reentrancy.
 */
interface ReentrancyErrors {
    /**
     * @dev Revert with an error when a caller attempts to reenter a protected
     *      function.
     */
    error NoReentrantCalls();
}