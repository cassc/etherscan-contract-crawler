// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaPointsRepository {
    function add(address _receiver, uint256 _quantity) external;
    function subtract(address _receiver, uint256 _quantity) external;
}