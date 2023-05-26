// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

import "forge-std/interfaces/IERC20.sol";

interface IVotingEscrow is IERC20 {

    /**
     * @notice Returns the vote power of `account`.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the total vote power of all locked tokens.
    */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the current amount of votes that `account` has.
     * it is same with balanceOf(account)
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @notice Creates a new lock for `value` tokens that will unlock at `unlockTime`. 
     * @param value The number of tokens to be locked.
     * @param unlockTime The unix timestamp when the tokens will unlock.
     */
    function createLock(uint256 value, uint256 unlockTime) external;

    /**
     * @notice Creates a new lock for `value` tokens that will unlock at `unlockTime`,
     * and `account` can permit to spend.
     * @dev `deadline`, `v`, `r`, `s` are used for permit.
     * @param value The number of tokens to be locked.
     * @param unlockTime The unix timestamp when the tokens will unlock.
     * @param deadline The time at which to expire the signature.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function createLockWithPermit(
        uint256 value,
        uint256 unlockTime,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Increase the amount of tokens that are locked.
     * @dev The lock must be exiting and not expired.
     * @param value The number of tokens to be increased.
     */
    function increaseAmount(uint256 value) external;

    /**
     * @notice Increase the unlock time of the lock.
     * @dev The lock must be exiting and not expired.
     * @param unlockTime The new unix timestamp when the tokens will unlock.
     */
    function increaseUnlockTime(uint256 unlockTime) external;

    /**
     * @notice Withdraws the tokens that have been unlocked.
     * @dev The lock must be expired.
     */
    function withdraw() external;

    /**
     * @notice Force withdraws the tokens that have been unlocked, and you will be charged a penalty.
     */
    function quitLock() external;

}