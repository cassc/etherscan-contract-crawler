// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IConverterMintableERC721 {
    function converterMint(
        address receiver,
        // uint256 quantity,
        uint256[] calldata oldTokenIds
    ) external;
}