// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./PoolBase.sol";
import "../libraries/Decimal.sol";

/// @notice This contract describes Pool's external view functions for observing it's current state
abstract contract PoolMetadata is PoolBase {
    using Decimal for uint256;

    /// @notice Function that returns cp-token decimals
    /// @return Cp-token decimals
    function decimals() public view virtual override returns (uint8) {
        return IERC20MetadataUpgradeable(address(currency)).decimals();
    }

    /// @notice Function returns pool's symbol
    /// @return Pool's symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice Function returns current (with accrual) pool state
    /// @return Current state
    function state() external view returns (State) {
        return _state(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) last accrual timestamp
    /// @return Last accrual timestamp
    function lastAccrual() external view returns (uint256) {
        return _accrueInterestVirtual().lastAccrual;
    }

    /// @notice Function returns current (with accrual) interest value
    /// @return Current interest
    function interest() external view returns (uint256) {
        return _interest(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) amount of funds available to LP for withdrawal
    /// @return Current available to withdraw funds
    function availableToWithdraw() external view returns (uint256) {
        if (debtClaimed) {
            return cash();
        } else {
            BorrowInfo memory info = _accrueInterestVirtual();
            return
                MathUpgradeable.min(
                    _availableToProviders(info),
                    _availableProvisionalDefault(info)
                );
        }
    }

    /// @notice Function returns current (with accrual) amount of funds available for manager to borrow
    /// @return Current available to borrow funds
    function availableToBorrow() external view returns (uint256) {
        return _availableToBorrow(_accrueInterestVirtual());
    }

    /// @notice Function returns current (with accrual) pool size
    /// @return Current pool size

    function poolSize() external view returns (uint256) {
        return _poolSize(_accrueInterestVirtual());
    }

    /// @notice Function returns current principal value
    /// @return Current principal
    function principal() external view returns (uint256) {
        return _info.principal;
    }

    /// @notice Function returns current (with accrual) total borrows value
    /// @return Current borrows
    function borrows() external view returns (uint256) {
        return _accrueInterestVirtual().borrows;
    }

    /// @notice Function returns current (with accrual) reserves value
    /// @return Current reserves
    function reserves() public view returns (uint256) {
        return _accrueInterestVirtual().reserves;
    }

    /// @notice Function returns current (with accrual) insurance value
    /// @return Current insurance
    function insurance() external view returns (uint256) {
        return _accrueInterestVirtual().insurance;
    }

    /// @notice Function returns timestamp when pool entered zero utilization state (0 if didn't enter)
    /// @return Timestamp of entering zero utilization
    function enteredZeroUtilization() external view returns (uint256) {
        return _info.enteredZeroUtilization;
    }

    /// @notice Function returns timestamp when pool entered warning utilization state (0 if didn't enter)
    /// @return Timestamp of entering warning utilization
    function enteredProvisionalDefault() external view returns (uint256) {
        return _accrueInterestVirtual().enteredProvisionalDefault;
    }

    /// @notice Function returns current (with accrual) exchange rate of rTokens for currency tokens
    /// @return Current exchange rate as 10-digits decimal
    function getCurrentExchangeRate() external view returns (uint256) {
        if (totalSupply() == 0) {
            return Decimal.ONE;
        } else if (debtClaimed) {
            return cash().divDecimal(totalSupply());
        } else {
            BorrowInfo memory info = _accrueInterestVirtual();
            return
                (_availableToProviders(info) + info.borrows).divDecimal(
                    totalSupply()
                );
        }
    }

    /// @notice Function to get current borrow interest rate
    /// @return Borrow interest rate as 18-digit decimal
    function getBorrowRate() public view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.getBorrowRate(
                cash(),
                info.borrows,
                info.reserves + info.insurance + (info.borrows - info.principal)
            );
    }

    /// @notice Function to get current supply interest rate
    /// @return Supply interest rate as 18-digit decimal
    function getSupplyRate() external view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.getSupplyRate(
                cash(),
                info.borrows,
                info.reserves +
                    info.insurance +
                    (info.borrows - info.principal),
                reserveFactor + insuranceFactor
            );
    }

    /// @notice Function to get current utilization rate
    /// @return Utilization rate as 18-digit decimal
    function getUtilizationRate() external view returns (uint256) {
        BorrowInfo memory info = _accrueInterestVirtual();
        return
            interestRateModel.utilizationRate(
                cash(),
                info.borrows,
                info.insurance + info.reserves + _interest(info)
            );
    }
}