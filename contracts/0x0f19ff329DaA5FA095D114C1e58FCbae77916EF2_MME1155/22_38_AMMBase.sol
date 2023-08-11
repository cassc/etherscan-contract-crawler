// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IAMMBase} from "../interfaces/IAMMBase.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {Pool1155Logic} from "../libraries/Pool1155Logic.sol";

/**
 * @title AMMBase
 * @author Souq.Finance
 * @notice The Base contract to be inherited by MMEs
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
contract AMMBase is IAMMBase {
    using Math for uint256;
    uint256 public yieldReserve;
    address public immutable addressesRegistry;
    DataTypes.PoolData public poolData;

    constructor(address _registry) {
        require(_registry != address(0), Errors.ADDRESS_IS_ZERO);
        addressesRegistry = _registry;
    }

    /**
     * @dev modifier for when the the msg sender is pool admin in the access manager
     */
    modifier onlyPoolAdmin() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev modifier for when the the msg sender is either pool admin or pool operations in the access manager
     */
    modifier onlyPoolAdminOrOperations() {
        require(
            IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender) ||
                IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolOperations(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN_OR_OPERATIONS
        );
        _;
    }

    /// @inheritdoc IAMMBase
    function setFee(DataTypes.PoolFee calldata newFee) external onlyPoolAdmin {
        poolData.fee.lpBuyFee = newFee.lpBuyFee;
        poolData.fee.lpSellFee = newFee.lpSellFee;
        poolData.fee.royaltiesBuyFee = newFee.royaltiesBuyFee;
        poolData.fee.royaltiesSellFee = newFee.royaltiesSellFee;
        poolData.fee.protocolBuyRatio = newFee.protocolBuyRatio;
        poolData.fee.protocolSellRatio = newFee.protocolSellRatio;
        poolData.fee.royaltiesAddress = newFee.royaltiesAddress;
        poolData.fee.protocolFeeAddress = newFee.protocolFeeAddress;
        emit FeeChanged(poolData.fee);
    }

    /// @inheritdoc IAMMBase
    function setPoolIterativeLimits(DataTypes.IterativeLimit calldata newLimits) external onlyPoolAdmin {
        poolData.iterativeLimit.minimumF = newLimits.minimumF;
        poolData.iterativeLimit.maxBulkStepSize = newLimits.maxBulkStepSize;
        poolData.iterativeLimit.iterations = newLimits.iterations;
        emit PoolIterativeLimitsSet(poolData.iterativeLimit);
    }

    /// @inheritdoc IAMMBase
    function setPoolLiquidityLimits(DataTypes.LiquidityLimit calldata newLimits) external onlyPoolAdmin {
        poolData.liquidityLimit.poolTvlLimit = newLimits.poolTvlLimit;
        poolData.liquidityLimit.cooldown = newLimits.cooldown;
        poolData.liquidityLimit.maxDepositPercentage = newLimits.maxDepositPercentage;
        poolData.liquidityLimit.maxWithdrawPercentage = newLimits.maxWithdrawPercentage;
        poolData.liquidityLimit.minFeeMultiplier = newLimits.minFeeMultiplier;
        poolData.liquidityLimit.maxFeeMultiplier = newLimits.maxFeeMultiplier;
        poolData.liquidityLimit.addLiqMode = newLimits.addLiqMode;
        poolData.liquidityLimit.removeLiqMode = newLimits.removeLiqMode;
        poolData.liquidityLimit.onlyAdminProvisioning = newLimits.onlyAdminProvisioning;
        emit PoolLiquidityLimitsSet(poolData.liquidityLimit);
    }

    /// @inheritdoc IAMMBase
    function setPoolData(DataTypes.PoolData calldata newPoolData) external onlyPoolAdmin {
        poolData.useAccessToken = newPoolData.useAccessToken;
        poolData.accessToken = newPoolData.accessToken;
        poolData.stableYieldAddress = newPoolData.stableYieldAddress;
        poolData.coefficientA = newPoolData.coefficientA;
        poolData.coefficientB = newPoolData.coefficientB;
        poolData.coefficientC = newPoolData.coefficientC;
        emit PoolDataSet(poolData);
    }
}