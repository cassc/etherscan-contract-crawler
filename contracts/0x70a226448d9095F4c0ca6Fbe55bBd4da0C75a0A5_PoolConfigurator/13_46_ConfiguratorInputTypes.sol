// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "./DataTypes.sol";

library ConfiguratorInputTypes {
    struct InitReserveInput {
        address xTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address auctionStrategyAddress;
        address underlyingAsset;
        DataTypes.AssetType assetType;
        address treasury;
        address incentivesController;
        string xTokenName;
        string xTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        bytes params;
    }

    struct UpdatePTokenInput {
        address asset;
        address treasury;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateNTokenInput {
        address asset;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateDebtTokenInput {
        address asset;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }
}