// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IZcToken {
    function mint(address, uint256) external returns (bool);

    function burn(address, uint256) external returns (bool);
}