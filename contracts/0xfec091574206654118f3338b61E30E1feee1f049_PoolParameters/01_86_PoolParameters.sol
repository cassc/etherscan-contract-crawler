// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ParaVersionedInitializable} from "../libraries/paraspace-upgradeability/ParaVersionedInitializable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {PoolLogic} from "../libraries/logic/PoolLogic.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {SupplyLogic} from "../libraries/logic/SupplyLogic.sol";
import {MarketplaceLogic} from "../libraries/logic/MarketplaceLogic.sol";
import {BorrowLogic} from "../libraries/logic/BorrowLogic.sol";
import {LiquidationLogic} from "../libraries/logic/LiquidationLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IERC20WithPermit} from "../../interfaces/IERC20WithPermit.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPoolParameters} from "../../interfaces/IPoolParameters.sol";
import {INToken} from "../../interfaces/INToken.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {FlashClaimLogic} from "../libraries/logic/FlashClaimLogic.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
import {IERC721Receiver} from "../../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IMarketplace} from "../../interfaces/IMarketplace.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ParaReentrancyGuard} from "../libraries/paraspace-upgradeability/ParaReentrancyGuard.sol";
import {IAuctionableERC721} from "../../interfaces/IAuctionableERC721.sol";
import {IReserveAuctionStrategy} from "../../interfaces/IReserveAuctionStrategy.sol";

/**
 * @title Pool Parameters contract
 *
 * @notice Main point of interaction with an ParaSpace protocol's market
 * - Users can:
 *   - mintToTreasury
 *   - ...
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract PoolParameters is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolParameters
{
    using ReserveLogic for DataTypes.ReserveData;

    IPoolAddressesProvider internal immutable ADDRESSES_PROVIDER;
    uint256 internal constant POOL_REVISION = 1;
    uint256 internal constant MAX_AUCTION_HEALTH_FACTOR = 2e18;
    uint256 internal constant MIN_AUCTION_HEALTH_FACTOR = 1e18;

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     **/
    modifier onlyPoolConfigurator() {
        _onlyPoolConfigurator();
        _;
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    function _onlyPoolConfigurator() internal view virtual {
        require(
            ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender,
            Errors.CALLER_NOT_POOL_CONFIGURATOR
        );
    }

    function _onlyPoolAdmin() internal view virtual {
        require(
            IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(
                msg.sender
            ),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /// @inheritdoc IPoolParameters
    function mintToTreasury(address[] calldata assets)
        external
        virtual
        override
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        PoolLogic.executeMintToTreasury(ps._reserves, assets);
    }

    /// @inheritdoc IPoolParameters
    function initReserve(
        address asset,
        address xTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress,
        address auctionStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        DataTypes.PoolStorage storage ps = poolStorage();

        if (
            PoolLogic.executeInitReserve(
                ps._reserves,
                ps._reservesList,
                DataTypes.InitReserveParams({
                    asset: asset,
                    xTokenAddress: xTokenAddress,
                    variableDebtAddress: variableDebtAddress,
                    interestRateStrategyAddress: interestRateStrategyAddress,
                    auctionStrategyAddress: auctionStrategyAddress,
                    reservesCount: ps._reservesCount,
                    maxNumberReserves: ReserveConfiguration.MAX_RESERVES_COUNT
                })
            )
        ) {
            ps._reservesCount++;
        }
    }

    /// @inheritdoc IPoolParameters
    function dropReserve(address asset)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        PoolLogic.executeDropReserve(ps._reserves, ps._reservesList, asset);
    }

    /// @inheritdoc IPoolParameters
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            ps._reserves[asset].id != 0 || ps._reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        ps._reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /// @inheritdoc IPoolParameters
    function setReserveAuctionStrategyAddress(
        address asset,
        address auctionStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            ps._reserves[asset].id != 0 || ps._reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        ps._reserves[asset].auctionStrategyAddress = auctionStrategyAddress;
    }

    /// @inheritdoc IPoolParameters
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external virtual override onlyPoolConfigurator {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            ps._reserves[asset].id != 0 || ps._reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        ps._reserves[asset].configuration = configuration;
    }

    /// @inheritdoc IPoolParameters
    function rescueTokens(
        DataTypes.AssetType assetType,
        address token,
        address to,
        uint256 amountOrTokenId
    ) external virtual override onlyPoolAdmin {
        PoolLogic.executeRescueTokens(assetType, token, to, amountOrTokenId);
    }

    /// @inheritdoc IPoolParameters
    function setAuctionRecoveryHealthFactor(uint64 value)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(value != 0, Errors.INVALID_AMOUNT);

        require(
            value > MIN_AUCTION_HEALTH_FACTOR &&
                value <= MAX_AUCTION_HEALTH_FACTOR,
            Errors.INVALID_AMOUNT
        );

        ps._auctionRecoveryHealthFactor = value;
    }

    /// @inheritdoc IPoolParameters
    function getUserAccountData(address user)
        external
        view
        virtual
        override
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
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            PoolLogic.executeGetUserAccountData(
                user,
                ps,
                ADDRESSES_PROVIDER.getPriceOracle()
            );
    }

    function getAssetLtvAndLT(address asset, uint256 tokenId)
        external
        view
        virtual
        override
        returns (uint256 ltv, uint256 lt)
    {
        DataTypes.PoolStorage storage ps = poolStorage();
        return PoolLogic.executeGetAssetLtvAndLT(ps, asset, tokenId);
    }

    /// @inheritdoc IPoolParameters
    function setAuctionValidityTime(address user)
        external
        virtual
        override
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(user != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
            user
        ];
        (, , , , , , uint256 erc721HealthFactor) = PoolLogic
            .executeGetUserAccountData(
                user,
                ps,
                ADDRESSES_PROVIDER.getPriceOracle()
            );
        require(
            erc721HealthFactor > ps._auctionRecoveryHealthFactor,
            Errors.ERC721_HEALTH_FACTOR_NOT_ABOVE_THRESHOLD
        );
        userConfig.auctionValidityTime = block.timestamp;
    }
}