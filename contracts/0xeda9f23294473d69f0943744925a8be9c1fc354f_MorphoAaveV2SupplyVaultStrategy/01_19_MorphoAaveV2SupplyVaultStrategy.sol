// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./MorphoSupplyVaultStrategy.sol";

contract MorphoAaveV2SupplyVaultStrategy is MorphoSupplyVaultStrategy {
    /// @dev return always a value which is multiplied by 1e18
    ///     eg for 2% apr -> 2*1e18
    function getApr() external view override returns (uint256 apr) {
        // The supply rate per year experienced on average on the given market (in WAD).
        (uint256 ratePerYear, , ) = AAVE_LENS.getAverageSupplyRatePerYear(poolToken);
        apr = ratePerYear / 1e7;
    }
}