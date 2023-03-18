// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionManager {
    function register(
        address _collectionProxy,
        address _collectionStorage,
        address _mintFeeERC20AssetProxy,
        uint256 _mintFeeERC20,
        uint256[4] calldata _mintFeeETH
        // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
    ) external;
}