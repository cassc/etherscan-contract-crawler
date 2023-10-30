// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund/comptroller/ComptrollerLib.sol";
import "../extensions/fee-manager/FeeManager.sol";

/// @title FundActionsWrapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice Logic related to funds, not necessary in the core protocol
/// @dev This contract is currently unaudited, as it does not involve any
/// exchange in value, and simply wraps other functions for convenience
contract FundActionsWrapper {
    address private immutable FEE_MANAGER;

    constructor(address _feeManager) public {
        FEE_MANAGER = _feeManager;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the net value of 1 unit of shares in the fund's denomination asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return netShareValue_ The amount of the denomination asset per share
    /// @return isValid_ True if the conversion rates to derive the value are all valid
    /// @dev Accounts for fees outstanding. This is a convenience function for external consumption
    /// that can be used to determine the cost of purchasing shares at any given point in time.
    /// It essentially just bundles settling all fees that implement the Continuous hook and then
    /// looking up the gross share value.
    function calcNetShareValueForFund(address _comptrollerProxy)
        external
        returns (uint256 netShareValue_, bool isValid_)
    {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 0, "");

        return comptrollerProxyContract.calcGrossShareValue(false);
    }

    /// @notice Invokes the Continuous fee hook on all specified fees, and then attempts to payout
    /// any shares outstanding on those fees
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _fees The fees for which to run these actions
    /// @dev This is just a wrapper to execute two callOnExtension() actions atomically, in sequence.
    /// The caller must pass in the fees that they want to run this logic on.
    function invokeContinuousFeeHookAndPayoutSharesOutstandingForFund(
        address _comptrollerProxy,
        address[] calldata _fees
    ) external {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);

        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 0, "");
        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 1, abi.encode(_fees));
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets all fees that implement the `Continuous` fee hook for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return continuousFees_ The fees that implement the `Continuous` fee hook
    function getContinuousFeesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory continuousFees_)
    {
        FeeManager feeManagerContract = FeeManager(FEE_MANAGER);

        address[] memory fees = feeManagerContract.getEnabledFeesForFund(_comptrollerProxy);

        // Count the continuous fees
        uint256 continuousFeesCount;
        bool[] memory implementsContinuousHook = new bool[](fees.length);
        for (uint256 i; i < fees.length; i++) {
            if (feeManagerContract.feeSettlesOnHook(fees[i], IFeeManager.FeeHook.Continuous)) {
                continuousFeesCount++;
                implementsContinuousHook[i] = true;
            }
        }

        // Return early if no continuous fees
        if (continuousFeesCount == 0) {
            return new address[](0);
        }

        // Create continuous fees array
        continuousFees_ = new address[](continuousFeesCount);
        uint256 continuousFeesIndex;
        for (uint256 i; i < fees.length; i++) {
            if (implementsContinuousHook[i]) {
                continuousFees_[continuousFeesIndex] = fees[i];
                continuousFeesIndex++;
            }
        }

        return continuousFees_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() external view returns (address feeManager_) {
        return FEE_MANAGER;
    }
}