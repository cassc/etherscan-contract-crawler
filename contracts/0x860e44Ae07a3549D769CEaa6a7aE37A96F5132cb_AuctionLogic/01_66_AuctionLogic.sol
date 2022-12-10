// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {IReserveAuctionStrategy} from "../../../interfaces/IReserveAuctionStrategy.sol";

/**
 * @title AuctionLogic library
 *
 * @notice Implements actions involving NFT auctions
 **/
library AuctionLogic {
    event AuctionStarted(
        address indexed user,
        address indexed collateralAsset,
        uint256 indexed collateralTokenId
    );
    event AuctionEnded(
        address indexed user,
        address indexed collateralAsset,
        uint256 indexed collateralTokenId
    );

    struct AuctionLocalVars {
        uint256 erc721HealthFactor;
        address collateralXToken;
        DataTypes.AssetType assetType;
    }

    /**
     * @notice Function to tsatr auction on an ERC721 of a position if its ERC721 Health Factor drops below 1.
     * @dev Emits the `AuctionStarted()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the auction function
     **/
    function executeStartAuction(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteAuctionParams memory params
    ) external {
        AuctionLocalVars memory vars;
        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];

        vars.collateralXToken = collateralReserve.xTokenAddress;
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.user
        ];

        (, , , , , , , , vars.erc721HealthFactor, ) = GenericLogic
            .calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: params.reservesCount,
                    user: params.user,
                    oracle: params.priceOracle
                })
            );

        ValidationLogic.validateStartAuction(
            userConfig,
            collateralReserve,
            DataTypes.ValidateAuctionParams({
                user: params.user,
                auctionRecoveryHealthFactor: params.auctionRecoveryHealthFactor,
                erc721HealthFactor: vars.erc721HealthFactor,
                collateralAsset: params.collateralAsset,
                tokenId: params.collateralTokenId,
                xTokenAddress: vars.collateralXToken
            })
        );

        IAuctionableERC721(vars.collateralXToken).startAuction(
            params.collateralTokenId
        );

        emit AuctionStarted(
            params.user,
            params.collateralAsset,
            params.collateralTokenId
        );
    }

    /**
     * @notice Function to end auction on an ERC721 of a position if its ERC721 Health Factor increases back to above `AUCTION_RECOVERY_HEALTH_FACTOR`.
     * @dev Emits the `AuctionEnded()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the auction function
     **/
    function executeEndAuction(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteAuctionParams memory params
    ) external {
        AuctionLocalVars memory vars;
        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];
        vars.collateralXToken = collateralReserve.xTokenAddress;
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.user
        ];

        (, , , , , , , , vars.erc721HealthFactor, ) = GenericLogic
            .calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: params.reservesCount,
                    user: params.user,
                    oracle: params.priceOracle
                })
            );

        ValidationLogic.validateEndAuction(
            collateralReserve,
            DataTypes.ValidateAuctionParams({
                user: params.user,
                auctionRecoveryHealthFactor: params.auctionRecoveryHealthFactor,
                erc721HealthFactor: vars.erc721HealthFactor,
                collateralAsset: params.collateralAsset,
                tokenId: params.collateralTokenId,
                xTokenAddress: vars.collateralXToken
            })
        );

        IAuctionableERC721(vars.collateralXToken).endAuction(
            params.collateralTokenId
        );

        emit AuctionEnded(
            params.user,
            params.collateralAsset,
            params.collateralTokenId
        );
    }
}