// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IInterestRateModel {
    /* solhint-disable */
    struct Config {
        // uopt ∈ (0, 1) – optimal utilization;
        int256 uopt;
        // ucrit ∈ (uopt, 1) – threshold of large utilization;
        int256 ucrit;
        // ulow ∈ (0, uopt) – threshold of low utilization
        int256 ulow;
        // ki > 0 – integrator gain
        int256 ki;
        // kcrit > 0 – proportional gain for large utilization
        int256 kcrit;
        // klow ≥ 0 – proportional gain for low utilization
        int256 klow;
        // klin ≥ 0 – coefficient of the lower linear bound
        int256 klin;
        // beta ≥ 0 - a scaling factor
        int256 beta;
        // ri ≥ 0 – initial value of the integrator
        int256 ri;
        // Tcrit ≥ 0 - the time during which the utilization exceeds the critical value
        int256 Tcrit;
    }
    /* solhint-enable */

    /// @dev Set dedicated config for given asset in a Silo. Config is per asset per Silo so different assets
    /// in different Silo can have different configs.
    /// It will try to call `_silo.accrueInterest(_asset)` before updating config, but it is not guaranteed,
    /// that this call will be successful, if it fail config will be set anyway.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    function setConfig(address _silo, address _asset, Config calldata _config) external;

    /// @dev get compound interest rate and update model storage
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRateAndUpdate(
        address _asset,
        uint256 _blockTimestamp
    ) external returns (uint256 rcomp);

    /// @dev Get config for given asset in a Silo. If dedicated config is not set, default one will be returned.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    /// @return Config struct for asset in Silo
    function getConfig(address _silo, address _asset) external view returns (Config memory);

    /// @dev get compound interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    function getCompoundInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcomp);

    /// @dev get current annual interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function getCurrentInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcur);

    /// @notice get the flag to detect rcomp restriction (zero current interest) due to overflow
    /// overflow boolean flag to detect rcomp restriction
    function overflowDetected(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (bool overflow);

    /// @dev pure function that calculates current annual interest rate
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate (1e18 == 100%)
    function calculateCurrentInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (uint256 rcur);

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    /// @return overflow boolean flag to detect rcomp restriction
    function calculateCompoundInterestRateWithOverflowDetection(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit, // solhint-disable-line var-name-mixedcase
        bool overflow
    );

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _totalBorrowAmount current total borrows for asset
    /// @param _totalDeposits current total deposits for asset
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now (1e18 == 100%)
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    function calculateCompoundInterestRate(
        Config memory _c,
        uint256 _totalDeposits,
        uint256 _totalBorrowAmount,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit // solhint-disable-line var-name-mixedcase
    );

    /// @dev returns decimal points used by model
    function DP() external pure returns (uint256); // solhint-disable-line func-name-mixedcase

    /// @dev just a helper method to see if address is a InterestRateModel
    /// @return always true
    function interestRateModelPing() external pure returns (bytes4);
}