// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPropertyToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function mintReserved(address _address, uint256 _amount) external;
}