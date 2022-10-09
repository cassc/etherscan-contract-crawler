// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ILSSVMRouter {
    struct PairSwapAny {
        address pair;
        uint256 numItems;
    }

    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);
}