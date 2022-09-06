// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   PayableProxyInterface
 * @author  OpenSea Protocol Team
 * @notice  PayableProxyInterface contains all external function interfaces
 *          for the payable proxy.
 */
interface PayableProxyInterface {
    /**
     * @dev Fallback function that delegates calls to the address returned by
     *      `_implementation()`. Will run if no other function in the contract
     *      matches the call data.
     */
    fallback() external payable;
}