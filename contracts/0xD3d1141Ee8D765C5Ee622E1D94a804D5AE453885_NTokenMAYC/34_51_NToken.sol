// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

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
import {IInitializableNToken} from "../../interfaces/IInitializableNToken.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {MintableIncentivizedERC721} from "./base/MintableIncentivizedERC721.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";

/**
 * @title ParaSpace ERC721 NToken
 *
 * @notice Implementation of the NFT derivative token for the ParaSpace protocol
 */
contract NToken is VersionedInitializable, MintableIncentivizedERC721, INToken {
    using SafeERC20 for IERC20;

    uint256 public constant NTOKEN_REVISION = 131;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return NTOKEN_REVISION;
    }

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool, bool atomic_pricing)
        MintableIncentivizedERC721(
            pool,
            "NTOKEN_IMPL",
            "NTOKEN_IMPL",
            atomic_pricing
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
        _underlyingAsset = underlyingAsset;
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
        uint256[] calldata tokenIds
    ) external virtual override onlyPool nonReentrant returns (uint64, uint64) {
        return _burn(from, receiverOfUnderlying, tokenIds);
    }

    function _burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds
    ) internal returns (uint64, uint64) {
        (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        ) = _burnMultiple(from, tokenIds);

        if (receiverOfUnderlying != address(this)) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                IERC721(_underlyingAsset).safeTransferFrom(
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

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyPoolAdmin {
        IERC20(token).safeTransfer(to, amount);
        emit RescueERC20(token, to, amount);
    }

    function rescueERC721(
        address token,
        address to,
        uint256[] calldata ids
    ) external override onlyPoolAdmin {
        require(
            token != _underlyingAsset,
            Errors.UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED
        );
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit RescueERC721(token, to, ids);
    }

    function rescueERC1155(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyPoolAdmin {
        IERC1155(token).safeBatchTransferFrom(
            address(this),
            to,
            ids,
            amounts,
            data
        );
        emit RescueERC1155(token, to, ids, amounts, data);
    }

    function executeAirdrop(
        address airdropContract,
        bytes calldata airdropParams
    ) external override onlyPoolAdmin {
        require(
            airdropContract != address(0),
            Errors.INVALID_AIRDROP_CONTRACT_ADDRESS
        );
        require(airdropParams.length >= 4, Errors.INVALID_AIRDROP_PARAMETERS);

        // call project airdrop contract
        Address.functionCall(
            airdropContract,
            airdropParams,
            Errors.CALL_AIRDROP_METHOD_FAILED
        );

        emit ExecuteAirdrop(airdropContract);
    }

    /// @inheritdoc INToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /// @inheritdoc INToken
    function transferUnderlyingTo(address target, uint256 tokenId)
        external
        virtual
        override
        onlyPool
        nonReentrant
    {
        IERC721(_underlyingAsset).safeTransferFrom(
            address(this),
            target,
            tokenId
        );
    }

    /// @inheritdoc INToken
    function handleRepayment(address user, uint256 amount)
        external
        virtual
        override
        onlyPool
        nonReentrant
    {
        // Intentionally left blank
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
        address underlyingAsset = _underlyingAsset;

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
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return IERC721Metadata(_underlyingAsset).tokenURI(tokenId);
    }

    function getAtomicPricingConfig() external view returns (bool) {
        return ATOMIC_PRICING;
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
}