// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGenesisTokenMinified {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}