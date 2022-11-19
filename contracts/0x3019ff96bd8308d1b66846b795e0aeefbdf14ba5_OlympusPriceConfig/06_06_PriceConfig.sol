// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {PRICEv1} from "modules/PRICE/PRICE.v1.sol";

import "src/Kernel.sol";

contract OlympusPriceConfig is Policy, RolesConsumer {
    // =========  STATE ========= //

    PRICEv1 internal PRICE;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("PRICE");
        dependencies[1] = toKeycode("ROLES");

        PRICE = PRICEv1(getModuleAddress(dependencies[0]));
        ROLES = ROLESv1(getModuleAddress(dependencies[1]));
    }

    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        Keycode PRICE_KEYCODE = PRICE.KEYCODE();

        permissions = new Permissions[](4);
        permissions[0] = Permissions(PRICE_KEYCODE, PRICE.initialize.selector);
        permissions[1] = Permissions(PRICE_KEYCODE, PRICE.changeMovingAverageDuration.selector);
        permissions[2] = Permissions(PRICE_KEYCODE, PRICE.changeObservationFrequency.selector);
        permissions[3] = Permissions(PRICE_KEYCODE, PRICE.changeUpdateThresholds.selector);
    }

    //============================================================================================//
    //                                      ADMIN FUNCTIONS                                       //
    //============================================================================================//

    /// @notice                     Initialize the price module
    /// @notice                     Access restricted to approved policies
    /// @param startObservations_   Array of observations to initialize the moving average with. Must be of length numObservations.
    /// @param lastObservationTime_ Unix timestamp of last observation being provided (in seconds).
    /// @dev This function must be called after the Price module is deployed to activate it and after updating the observationFrequency
    ///      or movingAverageDuration (in certain cases) in order for the Price module to function properly.
    function initialize(uint256[] memory startObservations_, uint48 lastObservationTime_)
        external
        onlyRole("price_admin")
    {
        PRICE.initialize(startObservations_, lastObservationTime_);
    }

    /// @notice                         Change the moving average window (duration)
    /// @param movingAverageDuration_   Moving average duration in seconds, must be a multiple of observation frequency
    /// @dev Setting the window to a larger number of observations than the current window will clear
    ///      the data in the current window and require the initialize function to be called again.
    ///      Ensure that you have saved the existing data and can re-populate before calling this
    ///      function with a number of observations larger than have been recorded.
    function changeMovingAverageDuration(uint48 movingAverageDuration_)
        external
        onlyRole("price_admin")
    {
        PRICE.changeMovingAverageDuration(movingAverageDuration_);
    }

    /// @notice   Change the observation frequency of the moving average (i.e. how often a new observation is taken)
    /// @param    observationFrequency_   Observation frequency in seconds, must be a divisor of the moving average duration
    /// @dev      Changing the observation frequency clears existing observation data since it will not be taken at the right time intervals.
    ///           Ensure that you have saved the existing data and/or can re-populate before calling this function.
    function changeObservationFrequency(uint48 observationFrequency_)
        external
        onlyRole("price_admin")
    {
        PRICE.changeObservationFrequency(observationFrequency_);
    }

    /// @notice   Change the update thresholds for the price feeds
    /// @param    ohmEthUpdateThreshold_ - Maximum allowed time between OHM/ETH price feed updates
    /// @param    reserveEthUpdateThreshold_ - Maximum allowed time between Reserve/ETH price feed updates
    /// @dev      The update thresholds should be set based on the update threshold of the chainlink oracles.
    function changeUpdateThresholds(
        uint48 ohmEthUpdateThreshold_,
        uint48 reserveEthUpdateThreshold_
    ) external onlyRole("price_admin") {
        PRICE.changeUpdateThresholds(ohmEthUpdateThreshold_, reserveEthUpdateThreshold_);
    }
}