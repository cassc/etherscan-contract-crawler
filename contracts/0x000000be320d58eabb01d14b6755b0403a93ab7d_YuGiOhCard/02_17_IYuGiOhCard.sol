// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

/**
 * @dev Required interface of an YuGiOhCard minter.
 */
interface IYuGiOhCard {
    function mint(address to, uint256 amount) external;
}