// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinterPool {
    function onTransferToBlackHole(
        address from,
        address to,
        uint256 amount
    ) external;
}