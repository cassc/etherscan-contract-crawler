// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

interface IRegistry {
    function getModule(bytes1 identifier) external view returns (address);
    function setModule(bytes1 identifier, address module) external;
}