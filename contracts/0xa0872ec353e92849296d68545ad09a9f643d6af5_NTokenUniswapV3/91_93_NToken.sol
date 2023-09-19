// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC1155} from "../../dependencies/openzeppelin/contracts/IERC1155.sol";
import {IERC721Metadata} from "../../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
import {GPv2SafeERC20} from "../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {INToken} from "../../interfaces/INToken.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {MintableIncentivizedERC721} from "./base/MintableIncentivizedERC721.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";
import {ITimeLock} from "../../interfaces/ITimeLock.sol";
import {ITokenDelegation} from "../../interfaces/ITokenDelegation.sol";
import {IDelegationRegistry} from "../../dependencies/delegation/IDelegationRegistry.sol";

/**
 * @title ParaSpace ERC721 NToken
 *
 * @notice Implementation of the NFT derivative token for the ParaSpace protocol
 */
contract NToken is VersionedInitializable, MintableIncentivizedERC721, INToken {
    using SafeERC20 for IERC20;

    uint256 public constant NTOKEN_REVISION = 149;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return NTOKEN_REVISION;
    }

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(
        IPool pool,
        bool atomic_pricing,
        address delegateRegistry
    )
        MintableIncentivizedERC721(
            pool,
            "NTOKEN_IMPL",
            "NTOKEN_IMPL",
            atomic_pricing,
            delegateRegistry
        )
    {}

    function initialize(
        IPool initializingPool,
        address underlyingAsset,
        IRewardController incentivesController,
        string calldata nTokenName,
        string calldata nTokenSymbol,
        bytes calldata params
    ) public virtual override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(nTokenName);
        _setSymbol(nTokenSymbol);

        require(underlyingAsset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        _ERC721Data.underlyingAsset = underlyingAsset;
        _ERC721Data.rewardController = incentivesController;

        emit Initialized(
            underlyingAsset,
            address(POOL),
            address(incentivesController),
            nTokenName,
            nTokenSymbol,
            params
        );
    }

    /// @inheritdoc INToken
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external virtual override onlyPool nonReentrant returns (uint64, uint64) {
        return _mintMultiple(onBehalfOf, tokenData);
    }

    /// @inheritdoc INToken
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds,
        DataTypes.TimeLockParams calldata timeLockParams
    ) external virtual override onlyPool nonReentrant returns (uint64, uint64) {
        return _burn(from, receiverOfUnderlying, tokenIds, timeLockParams);
    }

    function _burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds,
        DataTypes.TimeLockParams calldata timeLockParams
    )
        internal
        returns (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        )
    {
        (oldCollateralizedBalance, newCollateralizedBalance) = _burnMultiple(
            from,
            tokenIds
        );

        if (receiverOfUnderlying != address(this)) {
            address underlyingAsset = _ERC721Data.underlyingAsset;
            if (timeLockParams.releaseTime != 0) {
                ITimeLock timeLock = POOL.TIME_LOCK();
                timeLock.createAgreement(
                    DataTypes.AssetType.ERC721,
                    timeLockParams.actionType,
                    underlyingAsset,
                    tokenIds,
                    receiverOfUnderlying,
                    timeLockParams.releaseTime
                );
                receiverOfUnderlying = address(timeLock);
            }

            for (uint256 index = 0; index < tokenIds.length; index++) {
                IERC721(underlyingAsset).safeTransferFrom(
                    address(this),
                    receiverOfUnderlying,
                    tokenIds[index]
                );
            }
        }

        return (oldCollateralizedBalance, newCollateralizedBalance);
    }

    /// @inheritdoc INToken
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external onlyPool nonReentrant {
        _transfer(from, to, value, false);
    }

    function setApprovalForAllTo(
        address token,
        address to,
        bool _approved
    ) external onlyPoolAdmin {
        IERC721(token).setApprovalForAll(to, _approved);
    }

    /// @inheritdoc INToken
    function transferUnderlyingTo(
        address target,
        uint256 tokenId,
        DataTypes.TimeLockParams calldata timeLockParams
    ) external virtual override onlyPool nonReentrant {
        address underlyingAsset = _ERC721Data.underlyingAsset;
        if (timeLockParams.releaseTime != 0) {
            ITimeLock timeLock = POOL.TIME_LOCK();
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            timeLock.createAgreement(
                DataTypes.AssetType.ERC721,
                timeLockParams.actionType,
                underlyingAsset,
                tokenIds,
                target,
                timeLockParams.releaseTime
            );
            target = address(timeLock);
        }

        IERC721(underlyingAsset).safeTransferFrom(
            address(this),
            target,
            tokenId
        );
    }

    /**
     * @notice Transfers the nTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param tokenId The amount getting transferred
     * @param validate True if the transfer needs to be validated, false otherwise
     **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bool validate
    ) internal virtual {
        address underlyingAsset = _ERC721Data.underlyingAsset;

        uint256 fromBalanceBefore;
        if (validate) {
            fromBalanceBefore = collateralizedBalanceOf(from);
        }
        bool isUsedAsCollateral = _transferCollateralizable(from, to, tokenId);

        if (validate) {
            POOL.finalizeTransferERC721(
                underlyingAsset,
                tokenId,
                from,
                to,
                isUsedAsCollateral,
                fromBalanceBefore
            );
        }
    }

    /**
     * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param tokenId The token id getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        _transfer(from, to, tokenId, true);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function UNDERLYING_ASSET_ADDRESS() external view returns (address) {
        return _ERC721Data.underlyingAsset;
    }

    function getXTokenType()
        external
        pure
        virtual
        override
        returns (XTokenType)
    {
        return XTokenType.NToken;
    }

    function claimUnderlying(
        address timeLockV1,
        uint256[] calldata agreementIds
    ) external virtual onlyPool {
        ITimeLock(timeLockV1).claim(agreementIds);
    }
}