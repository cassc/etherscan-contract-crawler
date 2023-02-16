//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISANGA {
    enum SaleState {
        Paused, // 0
        Open    // 1
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error EpochIsNotMintable(uint256 epoch);
    error ExceedsMaxRoyaltiesPercentage();
    error SalePhaseNotActive();
    error TokenAlreadyUsedThisEpoch(uint256 tokenId);
    error TokenIsNotGold(uint256 tokenId);
    error TokenIsNotSoulbound(uint256 tokenId);
    error TokenIsNotOwned(uint256 tokenId);
}