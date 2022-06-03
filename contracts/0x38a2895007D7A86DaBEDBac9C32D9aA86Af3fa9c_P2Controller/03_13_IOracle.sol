// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IOracle {
    function getPrice(address collection, address denotedToken) external view returns (uint256, bool);
}