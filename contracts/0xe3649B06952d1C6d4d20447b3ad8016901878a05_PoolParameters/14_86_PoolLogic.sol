// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {IXTokenType, XTokenType} from "../../../interfaces/IXTokenType.sol";

/**
 * @title PoolLogic library
 *
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
    using GPv2SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPool` for descriptions
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Initialize an asset reserve and add the reserve to the list of reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for initiation
     * @return true if appended, false if inserted at existing empty spot
     **/
    function executeInitReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.InitReserveParams memory params
    ) external returns (bool) {
        if (params.asset != DataTypes.SApeAddress) {
            require(Address.isContract(params.asset), Errors.NOT_CONTRACT);
        }
        reservesData[params.asset].init(
            params.xTokenAddress,
            params.variableDebtAddress,
            params.interestRateStrategyAddress,
            params.auctionStrategyAddress
        );

        bool reserveAlreadyAdded = reservesData[params.asset].id != 0 ||
            reservesList[0] == params.asset;
        require(!reserveAlreadyAdded, Errors.RESERVE_ALREADY_ADDED);

        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (reservesList[i] == address(0)) {
                reservesData[params.asset].id = i;
                reservesList[i] = params.asset;
                return false;
            }
        }

        require(
            params.reservesCount < params.maxNumberReserves,
            Errors.NO_MORE_RESERVES_ALLOWED
        );
        reservesData[params.asset].id = params.reservesCount;
        reservesList[params.reservesCount] = params.asset;
        return true;
    }

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param assetType The asset type of the token
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amountOrTokenId The amount or id of token to transfer
     */
    function executeRescueTokens(
        DataTypes.AssetType assetType,
        address token,
        address to,
        uint256 amountOrTokenId
    ) external {
        if (assetType == DataTypes.AssetType.ERC20) {
            IERC20(token).safeTransfer(to, amountOrTokenId);
        } else if (assetType == DataTypes.AssetType.ERC721) {
            IERC721(token).safeTransferFrom(address(this), to, amountOrTokenId);
        }
    }

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of xTokens
     * @param reservesData The state of all the reserves
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function executeMintToTreasury(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address[] calldata assets
    ) external {
        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];

            DataTypes.ReserveData storage reserve = reservesData[assetAddress];

            DataTypes.ReserveConfigurationMap
                memory reserveConfiguration = reserve.configuration;

            // this cover both inactive reserves and invalid reserves since the flag will be 0 for both
            if (
                !reserveConfiguration.getActive() ||
                reserveConfiguration.getAssetType() != DataTypes.AssetType.ERC20
            ) {
                continue;
            }

            uint256 accruedToTreasury = reserve.accruedToTreasury;

            if (accruedToTreasury != 0) {
                reserve.accruedToTreasury = 0;
                uint256 normalizedIncome = reserve.getNormalizedIncome();
                uint256 amountToMint = accruedToTreasury.rayMul(
                    normalizedIncome
                );
                IPToken(reserve.xTokenAddress).mintToTreasury(
                    amountToMint,
                    normalizedIncome
                );

                emit MintedToTreasury(assetAddress, amountToMint);
            }
        }
    }

    /**
     * @notice Drop a reserve
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param asset The address of the underlying asset of the reserve
     **/
    function executeDropReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        address asset
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        ValidationLogic.validateDropReserve(reservesList, reserve, asset);
        reservesList[reservesData[asset].id] = address(0);
        delete reservesData[asset];
    }

    /**
     * @notice Returns the user account data across all the reserves
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     * @return erc721HealthFactor The current erc721 health factor of the user
     **/
    function executeGetUserAccountData(
        address user,
        DataTypes.PoolStorage storage ps,
        address oracle
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        )
    {
        DataTypes.CalculateUserAccountDataParams memory params = DataTypes
            .CalculateUserAccountDataParams({
                userConfig: ps._usersConfig[user],
                reservesCount: ps._reservesCount,
                user: user,
                oracle: oracle
            });

        (
            totalCollateralBase,
            ,
            totalDebtBase,
            ltv,
            currentLiquidationThreshold,
            ,
            ,
            healthFactor,
            erc721HealthFactor,

        ) = GenericLogic.calculateUserAccountData(
            ps._reserves,
            ps._reservesList,
            params
        );

        availableBorrowsBase = GenericLogic.calculateAvailableBorrows(
            totalCollateralBase,
            totalDebtBase,
            ltv
        );
    }

    function executeGetAssetLtvAndLT(
        DataTypes.PoolStorage storage ps,
        address asset,
        uint256 tokenId
    ) external view returns (uint256 ltv, uint256 lt) {
        DataTypes.ReserveData storage assetReserve = ps._reserves[asset];
        DataTypes.ReserveConfigurationMap memory assetConfig = assetReserve
            .configuration;
        (uint256 collectionLtv, uint256 collectionLT, , , ) = assetConfig
            .getParams();
        XTokenType tokenType = IXTokenType(assetReserve.xTokenAddress)
            .getXTokenType();
        if (tokenType == XTokenType.NTokenUniswapV3) {
            return
                GenericLogic.getLtvAndLTForUniswapV3(
                    ps._reserves,
                    asset,
                    tokenId,
                    collectionLtv,
                    collectionLT
                );
        } else {
            return (collectionLtv, collectionLT);
        }
    }
}