//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStuckERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IStuckERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}