// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOriginETH {
    function rebaseOptIn() external;
    function rebaseOptOut() external;
}