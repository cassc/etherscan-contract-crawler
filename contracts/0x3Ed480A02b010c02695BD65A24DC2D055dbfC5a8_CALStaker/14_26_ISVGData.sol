// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ISVGData {
    function data() external view returns (string calldata);
}