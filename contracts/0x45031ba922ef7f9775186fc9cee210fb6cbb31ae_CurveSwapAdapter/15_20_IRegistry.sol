// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IRegistry {
    function get_n_coins(address pool) external view returns (uint256[2] memory);
}