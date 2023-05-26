// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface ITransferProxy {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external;
}