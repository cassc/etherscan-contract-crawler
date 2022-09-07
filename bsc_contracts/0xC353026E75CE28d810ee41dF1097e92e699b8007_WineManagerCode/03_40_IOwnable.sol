// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * see openzeppelin/contracts/access/Ownable.sol
 */
interface IOwnable {

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}