// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}