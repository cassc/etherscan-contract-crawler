// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PoolBase.sol";

/// @notice This contract describes pool's configuration functions
abstract contract PoolConfiguration is PoolBase {
    /// @notice Function is used to update pool's manager (only called through factory)
    /// @param manager_ New manager of the pool
    function setManager(address manager_) external onlyFactory {
        require(manager_ != address(0), "AIZ");
        manager = manager_;
    }

    /// @notice Function is used to update pool's interest rate model (only called by governor)
    /// @param interestRateModel_ New IRM of the pool
    function setInterestRateModel(IInterestRateModel interestRateModel_)
        external
        onlyGovernor
    {
        require(address(interestRateModel_) != address(0), "AIZ");

        _accrueInterest();
        interestRateModel = interestRateModel_;
    }

    /// @notice Function is used to update pool's reserve factor (only called by governor)
    /// @param reserveFactor_ New reserve factor of the pool
    function setReserveFactor(uint256 reserveFactor_) external onlyGovernor {
        require(reserveFactor + insuranceFactor <= Decimal.ONE, "GTO");
        reserveFactor = reserveFactor_;
    }

    /// @notice Function is used to update pool's insurance factor (only called by governor)
    /// @param insuranceFactor_ New insurance factor of the pool
    function setInsuranceFactor(uint256 insuranceFactor_)
        external
        onlyGovernor
    {
        require(reserveFactor + insuranceFactor <= Decimal.ONE, "GTO");
        insuranceFactor = insuranceFactor_;
    }

    /// @notice Function is used to update pool's warning utilization (only called by governor)
    /// @param warningUtilization_ New warning utilization of the pool
    function setWarningUtilization(uint256 warningUtilization_)
        external
        onlyGovernor
    {
        require(warningUtilization <= Decimal.ONE, "GTO");

        _accrueInterest();
        warningUtilization = warningUtilization_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's provisional default utilization (only called by governor)
    /// @param provisionalDefaultUtilization_ New provisional default utilization of the pool
    function setProvisionalDefaultUtilization(
        uint256 provisionalDefaultUtilization_
    ) external onlyGovernor {
        require(provisionalDefaultUtilization_ <= Decimal.ONE, "GTO");

        _accrueInterest();
        provisionalDefaultUtilization = provisionalDefaultUtilization_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's warning grace period (only called by governor)
    /// @param warningGracePeriod_ New warning grace period of the pool
    function setWarningGracePeriod(uint256 warningGracePeriod_)
        external
        onlyGovernor
    {
        _accrueInterest();
        warningGracePeriod = warningGracePeriod_;
        _checkUtilization();
    }

    /// @notice Function is used to update pool's max inactive period (only called by governor)
    /// @param maxInactivePeriod_ New max inactive period of the pool
    function setMaxInactivePeriod(uint256 maxInactivePeriod_)
        external
        onlyGovernor
    {
        _accrueInterest();
        maxInactivePeriod = maxInactivePeriod_;
    }

    /// @notice Function is used to update pool's period to start auction (only called by governor)
    /// @param periodToStartAuction_ New period to start auction of the pool
    function setPeriodToStartAuction(uint256 periodToStartAuction_)
        external
        onlyGovernor
    {
        periodToStartAuction = periodToStartAuction_;
    }

    /// @notice Function is used to update pool's symbol (only called by governor)
    /// @param symbol_ New symbol of the pool
    function setSymbol(string memory symbol_) external onlyGovernor {
        _symbol = symbol_;
    }

    /// @notice Defines if the manager can borrow
    /// @param canManagerBorrow_ New manager's borrow permission for the pool
    function setCanManagerBorrow(bool canManagerBorrow_) external onlyGovernor {
        canManagerBorrow = canManagerBorrow_;
    }
}