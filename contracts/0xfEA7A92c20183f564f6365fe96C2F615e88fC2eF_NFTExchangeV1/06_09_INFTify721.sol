// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTify721 {
    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;
}