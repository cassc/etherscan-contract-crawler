// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ISOUL {
    function mint(address user, uint256 money) external;

    function burn(address user, uint256 coins) external;
}