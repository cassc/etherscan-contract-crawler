// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;
pragma abicoder v2;

interface IDelegateV3 {
    function erc20Transfer(
        address sender,
        address receiver,
        address token,
        uint256 amount
    ) external;
    function erc721Transfer(
        address sender,
        address receiver,
        address token,
        uint256 tokenId
    )external;
}