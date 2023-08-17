// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interface/ILiquidationHelper.sol";

/// @notice Library for processing LiquidationScenarios data
library LiquidationScenarioDetector {
    function isFull0x(ILiquidationHelper.LiquidationScenario _scenario) internal pure returns (bool) {
        return _scenario == ILiquidationHelper.LiquidationScenario.Full0x
            || _scenario == ILiquidationHelper.LiquidationScenario.Full0xForce;
    }

    function isFull0xWithChange(ILiquidationHelper.LiquidationScenario _scenario) internal pure returns (bool) {
        return _scenario == ILiquidationHelper.LiquidationScenario.Full0xWithChange
            || _scenario == ILiquidationHelper.LiquidationScenario.Full0xWithChangeForce;
    }

    function isCollateral0x(ILiquidationHelper.LiquidationScenario _scenario) internal pure returns (bool) {
        return _scenario == ILiquidationHelper.LiquidationScenario.Collateral0x
            || _scenario == ILiquidationHelper.LiquidationScenario.Collateral0xForce;
    }

    function isInternal(ILiquidationHelper.LiquidationScenario _scenario) internal pure returns (bool) {
        return _scenario == ILiquidationHelper.LiquidationScenario.Internal
            || _scenario == ILiquidationHelper.LiquidationScenario.InternalForce;
    }

    function calculateEarnings(ILiquidationHelper.LiquidationScenario _scenario) internal pure returns (bool) {
        return _scenario == ILiquidationHelper.LiquidationScenario.Internal
            || _scenario == ILiquidationHelper.LiquidationScenario.Collateral0x
            || _scenario == ILiquidationHelper.LiquidationScenario.Full0x
            || _scenario == ILiquidationHelper.LiquidationScenario.Full0xWithChange;
    }
}