// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStargateFeeLibrary.sol";

interface IWrapperV05 is IStargateFeeLibrary {

    function poolIdToPrice(uint _poolId) external view returns (Price memory);

    function isTokenPriceChanged(uint256 _poolId) external view returns (bool, uint256, PriceDeviationState);

    enum PriceDeviationState {
        Normal,
        Drift,
        Depeg
    }

    struct Price {
        address priceFeedAddress;
        uint256 basePriceSD; // e.g. $1 for USD token
        uint256 currentPriceSD; // price of the pool's token in USD
        PriceDeviationState state; // default is Normal
        uint16[] remoteChainIds; // chainIds of the pools that are connected to the pool
    }

}