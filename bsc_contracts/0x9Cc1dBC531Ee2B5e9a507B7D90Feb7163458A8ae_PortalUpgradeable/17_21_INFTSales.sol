//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INFTSales {
    function batchMintAndAssignNFTType(
        address recipient,
        uint16 amount,
        uint16 nftType
    ) external returns (uint32[] memory);

    function mintAndAssignNFTType(
        address recipient,
        uint16 nftType
    ) external returns (uint32);
}