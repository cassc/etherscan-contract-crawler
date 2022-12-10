// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ConfiguratorInputTypes} from "../protocol/libraries/types/ConfiguratorInputTypes.sol";

/**
 * @title IPoolConfigurator
 *
 * @notice Defines the basic interface for a Pool configurator.
 **/
interface IPoolConfigurator {
    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param xToken The address of the associated xToken contract
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed asset,
        address indexed xToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );

    /**
     * @dev Emitted when borrowing is enabled or disabled on a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing is enabled, false otherwise
     **/
    event ReserveBorrowing(address indexed asset, bool enabled);

    /**
     * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     **/
    event CollateralConfigurationChanged(
        address indexed asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    );

    /**
     * @dev Emitted when a reserve is activated or deactivated
     * @param asset The address of the underlying asset of the reserve
     * @param active True if reserve is active, false otherwise
     **/
    event ReserveActive(address indexed asset, bool active);

    /**
     * @dev Emitted when a reserve is frozen or unfrozen
     * @param asset The address of the underlying asset of the reserve
     * @param frozen True if reserve is frozen, false otherwise
     **/
    event ReserveFrozen(address indexed asset, bool frozen);

    /**
     * @dev Emitted when a reserve is paused or unpaused
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if reserve is paused, false otherwise
     **/
    event ReservePaused(address indexed asset, bool paused);

    /**
     * @dev Emitted when a reserve is dropped.
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveDropped(address indexed asset);

    /**
     * @dev Emitted when a reserve factor is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldReserveFactor The old reserve factor, expressed in bps
     * @param newReserveFactor The new reserve factor, expressed in bps
     **/
    event ReserveFactorChanged(
        address indexed asset,
        uint256 oldReserveFactor,
        uint256 newReserveFactor
    );

    /**
     * @dev Emitted when the borrow cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldBorrowCap The old borrow cap
     * @param newBorrowCap The new borrow cap
     **/
    event BorrowCapChanged(
        address indexed asset,
        uint256 oldBorrowCap,
        uint256 newBorrowCap
    );

    /**
     * @dev Emitted when the supply cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldSupplyCap The old supply cap
     * @param newSupplyCap The new supply cap
     **/
    event SupplyCapChanged(
        address indexed asset,
        uint256 oldSupplyCap,
        uint256 newSupplyCap
    );

    /**
     * @dev Emitted when the liquidation protocol fee of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldFee The old liquidation protocol fee, expressed in bps
     * @param newFee The new liquidation protocol fee, expressed in bps
     **/
    event LiquidationProtocolFeeChanged(
        address indexed asset,
        uint256 oldFee,
        uint256 newFee
    );

    /**
     * @dev Emitted when a reserve interest strategy contract is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldStrategy The address of the old interest strategy contract
     * @param newStrategy The address of the new interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        address indexed asset,
        address oldStrategy,
        address newStrategy
    );

    /**
     * @dev Emitted when a reserve auction strategy contract is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldStrategy The address of the old auction strategy contract
     * @param newStrategy The address of the new auction strategy contract
     **/
    event ReserveAuctionStrategyChanged(
        address indexed asset,
        address oldStrategy,
        address newStrategy
    );

    /**
     * @dev Emitted when an xToken implementation is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The xToken proxy address
     * @param implementation The new xToken implementation
     **/
    event XTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new xToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the the siloed borrowing state for an asset is changed.
     * @param asset The address of the underlying asset of the reserve
     * @param oldState The old siloed borrowing state
     * @param newState The new siloed borrowing state
     **/
    event SiloedBorrowingChanged(
        address indexed asset,
        bool oldState,
        bool newState
    );

    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     **/
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
    ) external;

    /**
     * @dev Updates the pToken implementation for the reserve.
     * @param input The pToken update parameters
     **/
    function updatePToken(
        ConfiguratorInputTypes.UpdatePTokenInput calldata input
    ) external;

    /**
     * @dev Updates the nToken implementation for the reserve.
     * @param input The nToken update parameters
     **/
    function updateNToken(
        ConfiguratorInputTypes.UpdateNTokenInput calldata input
    ) external;

    /**
     * @notice Updates the variable debt token implementation for the asset.
     * @param input The variableDebtToken update parameters
     **/
    function updateVariableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external;

    /**
     * @notice Configures borrowing on a reserve.
     * @dev Can only be disabled (set to false) if stable borrowing is disabled
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing needs to be enabled, false otherwise
     **/
    function setReserveBorrowing(address asset, bool enabled) external;

    /**
     * @notice Configures the reserve collateralization parameters.
     * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
     * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     **/
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    /**
     * @notice Activate or deactivate a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param active True if the reserve needs to be active, false otherwise
     **/
    function setReserveActive(address asset, bool active) external;

    /**
     * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
     * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
     * @param asset The address of the underlying asset of the reserve
     * @param freeze True if the reserve needs to be frozen, false otherwise
     **/
    function setReserveFreeze(address asset, bool freeze) external;

    /**
     * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
     * swap interest rate, liquidate, xtoken transfers).
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if pausing the reserve, false if unpausing
     **/
    function setReservePause(address asset, bool paused) external;

    /**
     * @notice set the auction recovery health factor
     * @param value The auction recovery health factor
     */
    function setAuctionRecoveryHealthFactor(uint64 value) external;

    /**
     * @notice Updates the reserve factor of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newReserveFactor The new reserve factor of the reserve
     **/
    function setReserveFactor(address asset, uint256 newReserveFactor) external;

    /**
     * @notice Sets the interest rate strategy of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newRateStrategyAddress The address of the new interest strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address newRateStrategyAddress
    ) external;

    /**
     * @notice Sets the auction strategy of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param newAuctionStrategyAddress The address of the new auction strategy contract
     **/
    function setReserveAuctionStrategyAddress(
        address asset,
        address newAuctionStrategyAddress
    ) external;

    /**
     * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
     * are suspended.
     * @param paused True if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool paused) external;

    /**
     * @notice Updates the borrow cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newBorrowCap The new borrow cap of the reserve
     **/
    function setBorrowCap(address asset, uint256 newBorrowCap) external;

    /**
     * @notice Updates the supply cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newSupplyCap The new supply cap of the reserve
     **/
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

    /**
     * @notice Updates the liquidation protocol fee of reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     **/
    function setLiquidationProtocolFee(address asset, uint256 newFee) external;

    /**
     * @notice Drops a reserve entirely.
     * @param asset The address of the reserve to drop
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Sets siloed borrowing for an asset
     * @param siloed The new siloed borrowing state
     */
    function setSiloedBorrowing(address asset, bool siloed) external;
}