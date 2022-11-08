// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/* ========== STRUCTS ========== */

/** @notice Vest struct
*   @param amount amount currently vested for user. changes as they claim, or if their vest is transferred to another address
*   @param lastClaim timestamp of the last time the user claimed. is initially set to 0.
*/
struct Vest {
    uint192 amount;
    uint64 lastClaim;
}

/** @notice Member struct
*   @param prev address to transfer vest from
*   @param next address to transfer vest to
*/
struct Member {
    address prev;
    address next;
}

/**
 * @notice {IBaseVesting} interface.
 *
 * @dev See {BaseVesting} for function descriptions.
 *
 */
interface IBaseVesting {
    /* ========== FUNCTIONS ========== */

    function total() external view returns (uint256);

    function begin() external;

    /* ========== EVENTS ========== */

    event VestingInitialized(uint256 duration);

    event Vested(address indexed from, uint256 amount);

    event Transferred(Member indexed members, uint256 amount);
}