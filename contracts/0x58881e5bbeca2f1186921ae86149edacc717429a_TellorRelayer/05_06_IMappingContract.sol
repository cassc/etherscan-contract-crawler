// SPDX-License-Identifier: MIT
pragma solidity 0.6.7;

interface IMappingContract{
    function getTellorID(bytes32 _id) external view returns(bytes32);
}