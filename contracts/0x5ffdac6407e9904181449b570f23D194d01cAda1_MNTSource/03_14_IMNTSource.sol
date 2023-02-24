// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MNTSource Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Minterest
 */
interface IMNTSource {
    /**
     * @notice Get keccak-256 hash of TOKEN_PROVIDER role
     */
    function TOKEN_PROVIDER() external view returns (bytes32);

    /**
     * @notice Get the block number when the MNTSource started
     */
    function dripStart() external view returns (uint256);

    /**
     * @notice Get tokens per block that to drip to target
     */
    function dripRate() external view returns (uint256);

    /**
     * @notice Get reference to token to drip
     */
    function token() external view returns (IERC20);

    /**
     * @notice Get target to receive dripped tokens
     */
    function target() external view returns (address);

    /**
     * @notice Get amount that has already been dripped
     */
    function dripped() external view returns (uint256);

    /**
     * @notice Drips the maximum amount of tokens to match the drip rate since inception
     * @dev Note: this will only drip up to the amount of tokens available.
     * @return The amount of tokens dripped in this call
     */
    function drip() external returns (uint256);

    /**
     * @notice Transfers MNT from TOKEN_PROVIDER caller and updates total MNT amount available for dripping.
     * @dev RESTRICTION: TOKEN_PROVIDER only
     */
    function refill(uint256 amount) external;

    /**
     * @notice Transfers MNT that was added to the contract without calling the refill to the specified recipient.
     * @dev Sweeps tokens only if token balance is greater than drip balance.
     * @dev RESTRICTION: Admin only
     */
    function sweep(uint256 amount, address recipient) external;
}