// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAccessManager {
    function isOperationalAddress(address _address) external view returns (bool);
}