// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { CPITStorage } from './CPITStorage.sol';
import { Constants } from '../lib/Constants.sol';

contract CPIT {
    uint256 constant WINDOW_SIZE = 6 hours; // window size for rolling 24 hours
    uint256 constant CPIT_LOCK_TIME = 1 days; // Lock time for exceeding the CPIT Threshold

    event CPITVaultLocked(uint256 lockedUntil);

    modifier isNotCPITLocked() {
        require(!_isCpitLocked(), 'CPIT: locked');
        _;
    }

    function _updatePriceImpact(
        uint preTransactionValue,
        uint postTransactionValue,
        uint max24HourCPITBips
    ) internal returns (uint priceImpactBips) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        // calculate price impact in BIPs
        priceImpactBips = _calculatePriceImpact(
            preTransactionValue,
            postTransactionValue
        );

        if (priceImpactBips == 0) {
            return priceImpactBips;
        }

        uint currentWindow = _getCurrentWindow();

        // update priceImpact for current window
        l.deviation[currentWindow] += priceImpactBips;

        uint cumulativePriceImpact = _calculateCumulativePriceImpact(
            currentWindow
        );

        // check if 24 hour cumulative price impact threshold is exceeded
        if (cumulativePriceImpact > max24HourCPITBips) {
            revert('price impact exceeded');
        }
    }

    function _cpitLockedUntil() internal view returns (uint256) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        return l.lockedUntil;
    }

    function _isCpitLocked() internal view returns (bool) {
        return _cpitLockedUntil() > block.timestamp;
    }

    function _getCurrentCpit() internal view returns (uint256) {
        return _calculateCumulativePriceImpact(_getCurrentWindow());
    }

    function _getCurrentWindow() internal view returns (uint256 currentWindow) {
        currentWindow = block.timestamp / WINDOW_SIZE;
    }

    // calculate the 24 hour cumulative price impact
    function _calculateCumulativePriceImpact(
        uint currentWindow
    ) internal view returns (uint cumulativePriceImpact) {
        CPITStorage.Layout storage l = CPITStorage.layout();
        uint windowsInDay = 24 hours / WINDOW_SIZE;
        uint startWindow = currentWindow - (windowsInDay - 1);
        for (uint256 i = startWindow; i <= currentWindow; i++) {
            cumulativePriceImpact += l.deviation[i];
        }
    }

    function _calculatePriceImpact(
        uint oldValue,
        uint newValue
    ) internal pure returns (uint priceImpactBips) {
        if (newValue >= oldValue) {
            return 0;
        }
        // Calculate the deviation between the old and new values
        uint deviation = oldValue - newValue;
        // Calculate the impact on price in basis points (BIPs)
        priceImpactBips = ((deviation * Constants.BASIS_POINTS_DIVISOR) /
            oldValue);
    }
}