// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IWhitelistedContract {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(
        address operator,
        bool approved
    ) external;
}