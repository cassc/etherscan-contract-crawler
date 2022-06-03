// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IMinimalProxy {
    function init(
        bytes memory extraData
    ) external;
}