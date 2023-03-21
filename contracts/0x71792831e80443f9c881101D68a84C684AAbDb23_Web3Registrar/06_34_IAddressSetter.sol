// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAddressSetter {
    function setAddr(bytes32 node, address a) external;
}