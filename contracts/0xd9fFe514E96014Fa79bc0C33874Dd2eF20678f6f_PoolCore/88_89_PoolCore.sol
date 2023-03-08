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
import {AuctionLogic} from "../libraries/logic/AuctionLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IERC20WithPermit} from "../../interfaces/IERC20WithPermit.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPoolCore} from "../../interfaces/IPoolCore.sol";
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
import {IWETH} from "../../misc/interfaces/IWETH.sol";

/**
 * @title Pool contract
 *
 * @notice Main point of interaction with an ParaSpace protocol's market
 * - Users can:
 *   - Supply
 *   - Withdraw
 *   - Borrow
 *   - Repay
 *   - Liquidate positions
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract PoolCore is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolCore
{
    using ReserveLogic for DataTypes.ReserveData;

    uint256 public constant POOL_REVISION = 145;
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    /**
     * @notice Initializes the Pool.
     * @dev Function is invoked by the proxy contract when the Pool contract is added to the
     * PoolAddressesProvider of the market.
     * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param provider The address of the PoolAddressesProvider
     **/
    function initialize(IPoolAddressesProvider provider)
        external
        virtual
        initializer
    {
        require(
            provider == ADDRESSES_PROVIDER,
            Errors.INVALID_ADDRESSES_PROVIDER
        );

        RGStorage storage rgs = rgStorage();

        rgs._status = _NOT_ENTERED;
    }

    /// @inheritdoc IPoolCore
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        SupplyLogic.executeSupply(
            ps._reserves,
            ps._usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                payer: msg.sender,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPoolCore
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        SupplyLogic.executeSupplyERC721(
            ps._reserves,
            ps._usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyERC721Params({
                asset: asset,
                tokenData: tokenData,
                onBehalfOf: onBehalfOf,
                payer: msg.sender,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPoolCore
    function supplyERC721FromNToken(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        SupplyLogic.executeSupplyERC721FromNToken(
            ps._reserves,
            ps._usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyERC721Params({
                asset: asset,
                tokenData: tokenData,
                onBehalfOf: onBehalfOf,
                payer: address(0),
                referralCode: 0
            })
        );
    }

    /// @inheritdoc IPoolCore
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        // Need to accommodate ERC721 and ERC1155 here
        IERC20WithPermit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );
        SupplyLogic.executeSupply(
            ps._reserves,
            ps._usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                payer: msg.sender,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPoolCore
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external virtual override nonReentrant returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            SupplyLogic.executeWithdraw(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawParams({
                    asset: asset,
                    amount: amount,
                    to: to,
                    reservesCount: ps._reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPoolCore
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) external virtual override nonReentrant returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            SupplyLogic.executeWithdrawERC721(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawERC721Params({
                    asset: asset,
                    tokenIds: tokenIds,
                    to: to,
                    reservesCount: ps._reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    function decreaseUniswapV3Liquidity(
        address asset,
        uint256 tokenId,
        uint128 liquidityDecrease,
        uint256 amount0Min,
        uint256 amount1Min,
        bool receiveEthAsWeth
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            SupplyLogic.executeDecreaseUniswapV3Liquidity(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteDecreaseUniswapV3LiquidityParams({
                    user: msg.sender,
                    asset: asset,
                    tokenId: tokenId,
                    reservesCount: ps._reservesCount,
                    liquidityDecrease: liquidityDecrease,
                    amount0Min: amount0Min,
                    amount1Min: amount1Min,
                    receiveEthAsWeth: receiveEthAsWeth,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPoolCore
    function borrow(
        address asset,
        uint256 amount,
        uint16 referralCode,
        address onBehalfOf
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        BorrowLogic.executeBorrow(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig[onBehalfOf],
            DataTypes.ExecuteBorrowParams({
                asset: asset,
                user: msg.sender,
                onBehalfOf: onBehalfOf,
                amount: amount,
                referralCode: referralCode,
                releaseUnderlying: true,
                reservesCount: ps._reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external virtual override nonReentrant returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            BorrowLogic.executeRepay(
                ps._reserves,
                ps._usersConfig[onBehalfOf],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    onBehalfOf: onBehalfOf,
                    payer: msg.sender,
                    usePTokens: false
                })
            );
    }

    /// @inheritdoc IPoolCore
    function repayWithPTokens(address asset, uint256 amount)
        external
        virtual
        override
        nonReentrant
        returns (uint256)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return
            BorrowLogic.executeRepay(
                ps._reserves,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    onBehalfOf: msg.sender,
                    payer: msg.sender,
                    usePTokens: true
                })
            );
    }

    /// @inheritdoc IPoolCore
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external virtual override nonReentrant returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();

        {
            IERC20WithPermit(asset).permit(
                msg.sender,
                address(this),
                amount,
                deadline,
                permitV,
                permitR,
                permitS
            );
        }
        {
            DataTypes.ExecuteRepayParams memory params = DataTypes
                .ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    onBehalfOf: onBehalfOf,
                    payer: msg.sender,
                    usePTokens: false
                });
            return
                BorrowLogic.executeRepay(
                    ps._reserves,
                    ps._usersConfig[onBehalfOf],
                    params
                );
        }
    }

    /// @inheritdoc IPoolCore
    function setUserUseERC20AsCollateral(address asset, bool useAsCollateral)
        external
        virtual
        override
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        SupplyLogic.executeUseERC20AsCollateral(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig[msg.sender],
            asset,
            useAsCollateral,
            ps._reservesCount,
            ADDRESSES_PROVIDER.getPriceOracle()
        );
    }

    function setUserUseERC721AsCollateral(
        address asset,
        uint256[] calldata tokenIds,
        bool useAsCollateral
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        if (useAsCollateral) {
            SupplyLogic.executeCollateralizeERC721(
                ps._reserves,
                ps._usersConfig[msg.sender],
                asset,
                tokenIds,
                msg.sender
            );
        } else {
            SupplyLogic.executeUncollateralizeERC721(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                asset,
                tokenIds,
                msg.sender,
                ps._reservesCount,
                ADDRESSES_PROVIDER.getPriceOracle()
            );
        }
    }

    /// @inheritdoc IPoolCore
    function liquidateERC20(
        address collateralAsset,
        address liquidationAsset,
        address borrower,
        uint256 liquidationAmount,
        bool receivePToken
    ) external payable virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        LiquidationLogic.executeLiquidateERC20(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.ExecuteLiquidateParams({
                reservesCount: ps._reservesCount,
                liquidationAmount: liquidationAmount,
                auctionRecoveryHealthFactor: ps._auctionRecoveryHealthFactor,
                weth: ADDRESSES_PROVIDER.getWETH(),
                collateralAsset: collateralAsset,
                liquidationAsset: liquidationAsset,
                borrower: borrower,
                liquidator: msg.sender,
                receiveXToken: receivePToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel(),
                collateralTokenId: 0
            })
        );
    }

    /// @inheritdoc IPoolCore
    function liquidateERC721(
        address collateralAsset,
        address borrower,
        uint256 collateralTokenId,
        uint256 maxLiquidationAmount,
        bool receiveNToken
    ) external payable virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        LiquidationLogic.executeLiquidateERC721(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.ExecuteLiquidateParams({
                reservesCount: ps._reservesCount,
                liquidationAmount: maxLiquidationAmount,
                auctionRecoveryHealthFactor: ps._auctionRecoveryHealthFactor,
                weth: ADDRESSES_PROVIDER.getWETH(),
                collateralAsset: collateralAsset,
                liquidationAsset: ADDRESSES_PROVIDER.getWETH(),
                collateralTokenId: collateralTokenId,
                borrower: borrower,
                liquidator: msg.sender,
                receiveXToken: receiveNToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function startAuction(
        address user,
        address collateralAsset,
        uint256 collateralTokenId
    ) external override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        AuctionLogic.executeStartAuction(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.ExecuteAuctionParams({
                reservesCount: ps._reservesCount,
                auctionRecoveryHealthFactor: ps._auctionRecoveryHealthFactor,
                collateralAsset: collateralAsset,
                collateralTokenId: collateralTokenId,
                user: user,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function endAuction(
        address user,
        address collateralAsset,
        uint256 collateralTokenId
    ) external override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        AuctionLogic.executeEndAuction(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.ExecuteAuctionParams({
                reservesCount: ps._reservesCount,
                auctionRecoveryHealthFactor: ps._auctionRecoveryHealthFactor,
                collateralAsset: collateralAsset,
                collateralTokenId: collateralTokenId,
                user: user,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function flashClaim(
        address receiverAddress,
        address[] calldata nftAssets,
        uint256[][] calldata nftTokenIds,
        bytes calldata params
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        FlashClaimLogic.executeFlashClaim(
            ps,
            DataTypes.ExecuteFlashClaimParams({
                receiverAddress: receiverAddress,
                nftAssets: nftAssets,
                nftTokenIds: nftTokenIds,
                params: params,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function getReserveData(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveData memory)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._reserves[asset];
    }

    /// @inheritdoc IPoolCore
    function getConfiguration(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._reserves[asset].configuration;
    }

    /// @inheritdoc IPoolCore
    function getUserConfiguration(address user)
        external
        view
        virtual
        override
        returns (DataTypes.UserConfigurationMap memory)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._usersConfig[user];
    }

    /// @inheritdoc IPoolCore
    function getReserveNormalizedIncome(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._reserves[asset].getNormalizedIncome();
    }

    /// @inheritdoc IPoolCore
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._reserves[asset].getNormalizedDebt();
    }

    /// @inheritdoc IPoolCore
    function getReservesList()
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        uint256 reservesListCount = ps._reservesCount;
        uint256 droppedReservesCount = 0;
        address[] memory reservesList = new address[](reservesListCount);

        for (uint256 i = 0; i < reservesListCount; i++) {
            if (ps._reservesList[i] != address(0)) {
                reservesList[i - droppedReservesCount] = ps._reservesList[i];
            } else {
                droppedReservesCount++;
            }
        }

        // Reduces the length of the reserves array by `droppedReservesCount`
        assembly {
            mstore(reservesList, sub(reservesListCount, droppedReservesCount))
        }
        return reservesList;
    }

    /// @inheritdoc IPoolCore
    function getReserveAddressById(uint16 id) external view returns (address) {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._reservesList[id];
    }

    /// @inheritdoc IPoolCore
    function MAX_NUMBER_RESERVES()
        external
        view
        virtual
        override
        returns (uint16)
    {
        return ReserveConfiguration.MAX_RESERVES_COUNT;
    }

    /// @inheritdoc IPoolCore
    function AUCTION_RECOVERY_HEALTH_FACTOR()
        external
        view
        virtual
        override
        returns (uint64)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        return ps._auctionRecoveryHealthFactor;
    }

    /// @inheritdoc IPoolCore
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external virtual override {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(
            msg.sender == ps._reserves[asset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );
        SupplyLogic.executeFinalizeTransferERC20(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.FinalizeTransferParams({
                asset: asset,
                from: from,
                to: to,
                usedAsCollateral: usedAsCollateral,
                amount: amount,
                balanceFromBefore: balanceFromBefore,
                balanceToBefore: balanceToBefore,
                reservesCount: ps._reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function finalizeTransferERC721(
        address asset,
        uint256 tokenId,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 balanceFromBefore
    ) external virtual override {
        DataTypes.PoolStorage storage ps = poolStorage();

        require(
            msg.sender == ps._reserves[asset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );
        SupplyLogic.executeFinalizeTransferERC721(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig,
            DataTypes.FinalizeTransferERC721Params({
                asset: asset,
                from: from,
                to: to,
                usedAsCollateral: usedAsCollateral,
                tokenId: tokenId,
                balanceFromBefore: balanceFromBefore,
                reservesCount: ps._reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPoolCore
    function getAuctionData(address ntokenAsset, uint256 tokenId)
        external
        view
        virtual
        override
        returns (DataTypes.AuctionData memory auctionData)
    {
        DataTypes.PoolStorage storage ps = poolStorage();

        address underlyingAsset = INToken(ntokenAsset)
            .UNDERLYING_ASSET_ADDRESS();
        DataTypes.ReserveData storage reserve = ps._reserves[underlyingAsset];
        require(
            reserve.id != 0 || ps._reservesList[0] == underlyingAsset,
            Errors.ASSET_NOT_LISTED
        );

        if (reserve.auctionStrategyAddress != address(0)) {
            uint256 startTime = IAuctionableERC721(ntokenAsset)
                .getAuctionData(tokenId)
                .startTime;
            IReserveAuctionStrategy auctionStrategy = IReserveAuctionStrategy(
                reserve.auctionStrategyAddress
            );

            auctionData.startTime = startTime;
            auctionData.asset = underlyingAsset;
            auctionData.tokenId = tokenId;
            auctionData.currentPriceMultiplier = auctionStrategy
                .calculateAuctionPriceMultiplier(startTime, block.timestamp);

            auctionData.maxPriceMultiplier = auctionStrategy
                .getMaxPriceMultiplier();
            auctionData.minExpPriceMultiplier = auctionStrategy
                .getMinExpPriceMultiplier();
            auctionData.minPriceMultiplier = auctionStrategy
                .getMinPriceMultiplier();
            auctionData.stepLinear = auctionStrategy.getStepLinear();
            auctionData.stepExp = auctionStrategy.getStepExp();
            auctionData.tickLength = auctionStrategy.getTickLength();
        }
    }

    // This function is necessary when receive erc721 from looksrare
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {
        require(
            msg.sender ==
                address(IPoolAddressesProvider(ADDRESSES_PROVIDER).getWETH()),
            "Receive not allowed"
        );
    }
}