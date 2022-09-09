// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInitializable {
    function init(bytes calldata data) external payable;
}