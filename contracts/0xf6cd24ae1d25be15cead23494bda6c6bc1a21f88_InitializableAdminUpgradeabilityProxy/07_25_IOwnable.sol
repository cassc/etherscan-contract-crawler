// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}