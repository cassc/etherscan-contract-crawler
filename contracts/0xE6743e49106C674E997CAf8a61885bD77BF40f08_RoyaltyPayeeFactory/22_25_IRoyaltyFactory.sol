// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IRoyaltyFactory {
    function create(bytes32 _node) external returns (address);
}