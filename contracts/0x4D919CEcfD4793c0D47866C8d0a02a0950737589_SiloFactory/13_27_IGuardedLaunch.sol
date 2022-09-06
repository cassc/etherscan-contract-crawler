// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IGuardedLaunch {
    /// @dev Stores info about maximum allowed liquidity in a Silo. This limit applies to deposit only.
    struct MaxLiquidityLimit {
        /// @dev flag to turn on/off all limits for all Silos
        bool globalLimit;
        /// @dev default value represents maximum allowed liquidity in Silo
        uint256 defaultMaxLiquidity;
        /// @notice siloMaxLiquidity maps silo => asset => maximum allowed deposit liquidity.
        /// @dev Deposit liquidity limit is denominated in quote token. For example, if set to 1e18, it means that any
        /// given Silo is allowed for deposits up to 1 quote token of value. Value is calculated using prices from the
        /// Oracle.
        mapping(address => mapping(address => uint256)) siloMaxLiquidity;
    }

    /// @dev Stores info about paused Silos
    /// if `globalPause` == `true`, all Silo are paused
    /// if `globalPause` == `false` and `siloPause[silo][0x0]` == `true`, all assets in a `silo` are paused
    /// if `globalPause` == `false` and `siloPause[silo][asset]` == `true`, only `asset` in a `silo` is paused
    struct Paused {
        bool globalPause;
        /// @dev maps silo address to asset address to bool
        mapping(address => mapping(address => bool)) siloPause;
    }

    /// @notice Emitted when all Silos are paused or unpaused
    /// @param globalPause current value of `globalPause`
    event GlobalPause(bool globalPause);

    /// @notice Emitted when a single Silo or single asset in a Silo is paused or unpaused
    /// @param silo address of Silo which is paused
    /// @param asset address of an asset which is paused
    /// @param pauseValue true when paused, otherwise false
    event SiloPause(address silo, address asset, bool pauseValue);

    /// @notice Emitted when max liquidity toggle is switched
    /// @param newLimitedMaxLiquidityState new value for max liquidity toggle
    event LimitedMaxLiquidityToggled(bool newLimitedMaxLiquidityState);

    /// @notice Emitted when deposit liquidity limit is changed for Silo and asset
    /// @param silo Silo address for which to set limit
    /// @param asset Silo asset for which to set limit
    /// @param newMaxDeposits deposit limit amount in quote token
    event SiloMaxDepositsLimitsUpdate(address indexed silo, address indexed asset, uint256 newMaxDeposits);

    /// @notice Emitted when default max liquidity limit is changed
    /// @param newMaxDeposits new deposit limit in quote token
    event DefaultSiloMaxDepositsLimitUpdate(uint256 newMaxDeposits);

    /// @notice Sets limited liquidity to provided value
    function setLimitedMaxLiquidity(bool _globalLimit) external;

    /// @notice Sets default deposit limit for all Silos
    /// @param _maxDeposits deposit limit amount in quote token
    function setDefaultSiloMaxDepositsLimit(uint256 _maxDeposits) external;

    /// @notice Sets deposit limit for Silo
    /// @param _silo Silo address for which to set limit
    /// @param _asset Silo asset for which to set limit
    /// @param _maxDeposits deposit limit amount in quote token
    function setSiloMaxDepositsLimit(
        address _silo,
        address _asset,
        uint256 _maxDeposits
    ) external;

    /// @notice Pause all Silos
    /// @dev Callable only by owner.
    /// @param _globalPause true to pause all Silos, otherwise false
    function setGlobalPause(bool _globalPause) external;

    /// @notice Pause single asset in a single Silo
    /// @dev Callable only by owner.
    /// @param _silo address of Silo in which `_asset` is being paused
    /// @param _asset address of an asset that is being paused
    /// @param _pauseValue true to pause, false to unpause
    function setSiloPause(address _silo, address _asset, bool _pauseValue) external;

    /// @notice Check given asset in a Silo is paused
    /// @param _silo address of Silo
    /// @param _asset address of an asset
    /// @return true if given asset in a Silo is paused, otherwise false
    function isSiloPaused(address _silo, address _asset) external view returns (bool);

    /// @notice Gets deposit limit for Silo
    /// @param _silo Silo address for which to set limit
    /// @param _asset Silo asset for which to set limit
    /// @return deposit limit for Silo
    function getMaxSiloDepositsValue(address _silo, address _asset) external view returns (uint256);
}