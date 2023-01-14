// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IReferee {
    function check(bytes memory data, bytes memory signature) external view;
}