// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IHoldingTime
 * @author Jeremy Guyet (@jguyet)
 * @dev Interface of the IHoldingTime is ERC20 dedicated function
 * for checking the hold time duration since the last transfer
 * excluding the purchases.
 */
interface IHoldingTime {
    /**
     * @dev Returns the timestamp of the last transfer or first purchase by `account`.
     */
    function holdTimeOf(address account) external view returns (uint256);
}