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
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IWETH} from "../../misc/interfaces/IWETH.sol";
import {ItemType} from "../../dependencies/seaport/contracts/lib/ConsiderationEnums.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPoolMarketplace} from "../../interfaces/IPoolMarketplace.sol";
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
 * @title Pool Marketplace contract
 *
 * @notice Main point of interaction with an ParaSpace protocol's market
 * - Users can:
 *   - buyWithCredit
 *   - acceptBidWithCredit
 *   - batchBuyWithCredit
 *   - batchAcceptBidWithCredit
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract PoolMarketplace is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolMarketplace
{
    using ReserveLogic for DataTypes.ReserveData;
    using SafeERC20 for IERC20;

    IPoolAddressesProvider internal immutable ADDRESSES_PROVIDER;
    uint256 internal constant POOL_REVISION = 130;

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

    /// @inheritdoc IPoolMarketplace
    function buyWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        uint16 referralCode
    ) external payable virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        MarketplaceLogic.executeBuyWithCredit(
            marketplaceId,
            payload,
            credit,
            ps,
            ADDRESSES_PROVIDER,
            referralCode
        );
    }

    /// @inheritdoc IPoolMarketplace
    function batchBuyWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        uint16 referralCode
    ) external payable virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        MarketplaceLogic.executeBatchBuyWithCredit(
            marketplaceIds,
            payloads,
            credits,
            ps,
            ADDRESSES_PROVIDER,
            referralCode
        );
    }

    /// @inheritdoc IPoolMarketplace
    function acceptBidWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        MarketplaceLogic.executeAcceptBidWithCredit(
            marketplaceId,
            payload,
            credit,
            onBehalfOf,
            ps,
            ADDRESSES_PROVIDER,
            referralCode
        );
    }

    /// @inheritdoc IPoolMarketplace
    function batchAcceptBidWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        MarketplaceLogic.executeBatchAcceptBidWithCredit(
            marketplaceIds,
            payloads,
            credits,
            onBehalfOf,
            ps,
            ADDRESSES_PROVIDER,
            referralCode
        );
    }
}