// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswapv3-periphery/interfaces/INonfungiblePositionManager.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {INTokenApeStaking} from "../../../interfaces/INTokenApeStaking.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {ITimeLockStrategy} from "../../../interfaces/ITimeLockStrategy.sol";
import {Errors} from "../helpers/Errors.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {XTokenType} from "../../../interfaces/IXTokenType.sol";
import {INTokenUniswapV3} from "../../../interfaces/INTokenUniswapV3.sol";
import {INTokenStakefish} from "../../../interfaces/INTokenStakefish.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {IStakefishNFTManager} from "../../../interfaces/IStakefishNFTManager.sol";
import {IStakefishValidator} from "../../../interfaces/IStakefishValidator.sol";
import {Helpers} from "../helpers/Helpers.sol";

/**
 * @title SupplyLogic library
 *
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );
    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode,
        bool fromNToken
    );

    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @notice Implements the supply feature. Through `supply()`, users supply assets to the ParaSpace protocol.
     * @dev Emits the `Supply()` event.
     * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
     * collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupply(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateSupply(
            reserveCache,
            params.amount,
            DataTypes.AssetType.ERC20
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.amount,
            0
        );

        if (params.payer == address(this)) {
            IERC20(params.asset).safeTransfer(
                reserveCache.xTokenAddress,
                params.amount
            );
        } else {
            IERC20(params.asset).safeTransferFrom(
                params.payer,
                reserveCache.xTokenAddress,
                params.amount
            );
        }

        bool isFirstSupply = IPToken(reserveCache.xTokenAddress).mint(
            msg.sender,
            params.onBehalfOf,
            params.amount,
            reserveCache.nextLiquidityIndex
        );

        if (isFirstSupply) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }

        emit Supply(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.amount,
            params.referralCode
        );
    }

    function executeSupplyERC721Base(
        uint16 reserveId,
        address nTokenAddress,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) internal {
        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);

        (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        ) = INToken(nTokenAddress).mint(params.onBehalfOf, params.tokenData);
        bool isFirstSupplyCollateral = (oldCollateralizedBalance == 0 &&
            newCollateralizedBalance > 0);
        if (isFirstSupplyCollateral) {
            userConfig.setUsingAsCollateral(reserveId, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }
    }

    /**
     * @notice Implements the supplyERC721 feature.
     * @dev Emits the `SupplyERC721()` event.
     * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
     * collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupplyERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSupply(
            reserveCache,
            params.tokenData.length,
            DataTypes.AssetType.ERC721
        );

        XTokenType tokenType = INToken(reserveCache.xTokenAddress)
            .getXTokenType();
        if (tokenType == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < params.tokenData.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    params.asset,
                    params.tokenData[index].tokenId,
                    true,
                    true,
                    true
                );
            }
        }
        if (tokenType == XTokenType.NTokenStakefish) {
            for (uint256 index = 0; index < params.tokenData.length; index++) {
                address validatorAddr = IStakefishNFTManager(params.asset)
                    .validatorForTokenId(params.tokenData[index].tokenId);
                IStakefishValidator.StateChange
                    memory lastState = IStakefishValidator(validatorAddr)
                        .lastStateChange();
                require(
                    lastState.state == IStakefishValidator.State.Active ||
                        lastState.state ==
                        IStakefishValidator.State.PostDeposit,
                    Errors.INVALID_STATE
                );
            }
        }
        if (
            tokenType == XTokenType.NTokenBAYC ||
            tokenType == XTokenType.NTokenMAYC
        ) {
            Helpers.setAssetUsedAsCollateral(
                userConfig,
                reservesData,
                DataTypes.SApeAddress,
                params.onBehalfOf
            );
        }
        for (uint256 index = 0; index < params.tokenData.length; index++) {
            IERC721(params.asset).safeTransferFrom(
                params.payer,
                reserveCache.xTokenAddress,
                params.tokenData[index].tokenId
            );
        }

        executeSupplyERC721Base(
            reserve.id,
            reserveCache.xTokenAddress,
            userConfig,
            params
        );

        emit SupplyERC721(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.tokenData,
            params.referralCode,
            false
        );
    }

    /**
     * @notice Implements the executeSupplyERC721FromNToken feature.
     * @dev Emits the `SupplyERC721()` event with fromNToken as true.
     * @dev same as `executeSupplyERC721` whereas no need to transfer the underlying nft
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupplyERC721FromNToken(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSupplyFromNToken(
            reserveCache,
            params,
            DataTypes.AssetType.ERC721
        );

        executeSupplyERC721Base(
            reserve.id,
            reserveCache.xTokenAddress,
            userConfig,
            params
        );

        emit SupplyERC721(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.tokenData,
            params.referralCode,
            true
        );
    }

    /**
     * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their xTokens for the underlying asset
     * previously supplied in the ParaSpace protocol.
     * @dev Emits the `Withdraw()` event.
     * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the withdraw function
     * @return The actual amount withdrawn
     */
    function executeWithdraw(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        uint256 userBalance = IPToken(reserveCache.xTokenAddress)
            .scaledBalanceOf(msg.sender)
            .rayMul(reserveCache.nextLiquidityIndex);

        uint256 amountToWithdraw = params.amount;

        if (params.amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        ValidationLogic.validateWithdraw(
            reserveCache,
            amountToWithdraw,
            userBalance
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            amountToWithdraw
        );

        DataTypes.TimeLockParams memory timeLockParams = GenericLogic
            .calculateTimeLockParams(
                reserve,
                DataTypes.TimeLockFactorParams({
                    assetType: DataTypes.AssetType.ERC20,
                    asset: params.asset,
                    amount: amountToWithdraw
                })
            );
        timeLockParams.actionType = DataTypes.TimeLockActionType.WITHDRAW;

        IPToken(reserveCache.xTokenAddress).burn(
            msg.sender,
            params.to,
            amountToWithdraw,
            reserveCache.nextLiquidityIndex,
            timeLockParams
        );

        if (userConfig.isUsingAsCollateral(reserve.id)) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC20(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (amountToWithdraw == userBalance) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit Withdraw(params.asset, msg.sender, params.to, amountToWithdraw);

        return amountToWithdraw;
    }

    function executeWithdrawERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawERC721Params memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);

        ValidationLogic.validateWithdrawERC721(
            reservesData,
            reserveCache,
            params.asset,
            params.tokenIds
        );
        uint256 amountToWithdraw = params.tokenIds.length;

        (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        ) = _burnNToken(reserveCache.xTokenAddress, reserve, params);

        bool isWithdrawCollateral = (newCollateralizedBalance <
            oldCollateralizedBalance);
        if (isWithdrawCollateral) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC721(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    params.tokenIds,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (newCollateralizedBalance == 0) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit WithdrawERC721(
            params.asset,
            msg.sender,
            params.to,
            params.tokenIds
        );

        return amountToWithdraw;
    }

    function _burnNToken(
        address xTokenAddress,
        DataTypes.ReserveData storage reserve,
        DataTypes.ExecuteWithdrawERC721Params memory params
    ) internal returns (uint64, uint64) {
        DataTypes.TimeLockParams memory timeLockParams = GenericLogic
            .calculateTimeLockParams(
                reserve,
                DataTypes.TimeLockFactorParams({
                    assetType: DataTypes.AssetType.ERC721,
                    asset: params.asset,
                    amount: params.tokenIds.length
                })
            );
        timeLockParams.actionType = DataTypes.TimeLockActionType.WITHDRAW;

        return
            INToken(xTokenAddress).burn(
                msg.sender,
                params.to,
                params.tokenIds,
                timeLockParams
            );
    }

    function executeDecreaseUniswapV3Liquidity(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteDecreaseUniswapV3LiquidityParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);
        INToken nToken = INToken(reserveCache.xTokenAddress);
        require(
            nToken.getXTokenType() == XTokenType.NTokenUniswapV3,
            Errors.XTOKEN_TYPE_NOT_ALLOWED
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = params.tokenId;
        ValidationLogic.validateWithdrawERC721(
            reservesData,
            reserveCache,
            params.asset,
            tokenIds
        );

        INTokenUniswapV3(reserveCache.xTokenAddress).decreaseUniswapV3Liquidity(
                params.user,
                params.tokenId,
                params.liquidityDecrease,
                params.amount0Min,
                params.amount1Min,
                params.receiveEthAsWeth
            );

        bool isUsedAsCollateral = ICollateralizableERC721(
            reserveCache.xTokenAddress
        ).isUsedAsCollateral(params.tokenId);
        if (isUsedAsCollateral) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC721(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    tokenIds,
                    params.user,
                    params.reservesCount,
                    params.oracle
                );
            }
        }
    }

    /**
     * @notice Validates a transfer of PTokens. The sender is subjected to health factor validation to avoid
     * collateralization constraints violation.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event for the `to` account, if the asset is being activated as
     * collateral.
     * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the finalizeTransfer function
     */
    function executeFinalizeTransferERC20(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.FinalizeTransferParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        ValidationLogic.validateTransferERC20(reserve);

        uint256 reserveId = reserve.id;

        if (params.from != params.to && params.amount != 0) {
            DataTypes.UserConfigurationMap storage fromConfig = usersConfig[
                params.from
            ];

            if (fromConfig.isUsingAsCollateral(reserveId)) {
                if (fromConfig.isBorrowingAny()) {
                    ValidationLogic.validateHFAndLtvERC20(
                        reservesData,
                        reservesList,
                        usersConfig[params.from],
                        params.asset,
                        params.from,
                        params.reservesCount,
                        params.oracle
                    );
                }

                if (params.balanceFromBefore == params.amount) {
                    fromConfig.setUsingAsCollateral(reserveId, false);
                    emit ReserveUsedAsCollateralDisabled(
                        params.asset,
                        params.from
                    );
                }

                if (params.balanceToBefore == 0) {
                    DataTypes.UserConfigurationMap
                        storage toConfig = usersConfig[params.to];

                    toConfig.setUsingAsCollateral(reserveId, true);
                    emit ReserveUsedAsCollateralEnabled(
                        params.asset,
                        params.to
                    );
                }
            }
        }
    }

    /**
     * @notice Validates a transfer of NTokens. The sender is subjected to health factor validation to avoid
     * collateralization constraints violation.
     * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the finalizeTransfer function
     */
    function executeFinalizeTransferERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.FinalizeTransferERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        ValidationLogic.validateTransferERC721(
            reservesData,
            reserve,
            params.asset,
            params.tokenId
        );

        uint256 reserveId = reserve.id;

        if (params.from != params.to) {
            DataTypes.UserConfigurationMap storage fromConfig = usersConfig[
                params.from
            ];

            if (params.usedAsCollateral) {
                if (fromConfig.isBorrowingAny()) {
                    uint256[] memory tokenIds = new uint256[](1);
                    tokenIds[0] = params.tokenId;
                    ValidationLogic.validateHFAndLtvERC721(
                        reservesData,
                        reservesList,
                        usersConfig[params.from],
                        params.asset,
                        tokenIds,
                        params.from,
                        params.reservesCount,
                        params.oracle
                    );
                }

                if (params.balanceFromBefore == 1) {
                    fromConfig.setUsingAsCollateral(reserveId, false);
                    emit ReserveUsedAsCollateralDisabled(
                        params.asset,
                        params.from
                    );
                }
            }
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUseERC20AsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        bool useAsCollateral,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        uint256 userBalance = IERC20(reserveCache.xTokenAddress).balanceOf(
            msg.sender
        );

        ValidationLogic.validateSetUseERC20AsCollateral(
            reserveCache,
            userBalance
        );

        if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id))
            return;

        if (useAsCollateral) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
        } else {
            userConfig.setUsingAsCollateral(reserve.id, false);
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC20(
                    reservesData,
                    reservesList,
                    userConfig,
                    asset,
                    msg.sender,
                    reservesCount,
                    priceOracle
                );
            }

            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate an asset as
     * collateral at any point in time.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param tokenIds The ids of the supplied ERC721 token
     * @param sender The address of NFT owner
     */
    function executeCollateralizeERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        uint256[] calldata tokenIds,
        address sender
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSetUseERC721AsCollateral(
            reservesData,
            reserveCache,
            asset,
            tokenIds
        );

        (
            uint256 oldCollateralizedBalance,
            uint256 newCollateralizedBalance
        ) = ICollateralizableERC721(reserveCache.xTokenAddress)
                .batchSetIsUsedAsCollateral(tokenIds, true, sender);

        if (oldCollateralizedBalance == 0 && newCollateralizedBalance != 0) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, sender);
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralDisabled()` event if the asset can be deactivated as collateral.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param tokenIds The ids of the supplied ERC721 token
     * @param sender The address of NFT owner
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUncollateralizeERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        uint256[] calldata tokenIds,
        address sender,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSetUseERC721AsCollateral(
            reservesData,
            reserveCache,
            asset,
            tokenIds
        );

        (
            uint256 oldCollateralizedBalance,
            uint256 newCollateralizedBalance
        ) = ICollateralizableERC721(reserveCache.xTokenAddress)
                .batchSetIsUsedAsCollateral(tokenIds, false, sender);

        if (oldCollateralizedBalance == newCollateralizedBalance) {
            return;
        }

        if (newCollateralizedBalance == 0) {
            userConfig.setUsingAsCollateral(reserve.id, false);
            emit ReserveUsedAsCollateralDisabled(asset, sender);
        }
        if (userConfig.isBorrowingAny()) {
            ValidationLogic.validateHFAndLtvERC721(
                reservesData,
                reservesList,
                userConfig,
                asset,
                tokenIds,
                sender,
                reservesCount,
                priceOracle
            );
        }
    }
}