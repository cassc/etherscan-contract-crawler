// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;
pragma abicoder v2;

interface IDelegate {
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