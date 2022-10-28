// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}