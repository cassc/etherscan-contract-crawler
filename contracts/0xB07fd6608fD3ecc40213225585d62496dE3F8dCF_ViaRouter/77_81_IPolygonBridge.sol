// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPolygonBridge {
    function depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) external;
}