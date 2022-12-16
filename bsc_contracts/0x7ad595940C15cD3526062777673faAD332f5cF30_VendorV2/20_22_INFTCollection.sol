// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTCollection {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function mintReserved(address _adrr, uint256 _amount) external;
}