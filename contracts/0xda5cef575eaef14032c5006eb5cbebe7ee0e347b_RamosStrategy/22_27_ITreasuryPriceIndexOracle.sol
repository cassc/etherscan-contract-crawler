pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/ITreasuryPriceIndexOracle.sol)

import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";

/**
 * @title Treasury Price Index Oracle
 * @notice The custom oracle (not dependant on external markets/AMMs/dependencies) to give the
 * Treasury Price Index, representing the target Treasury Value per token.
 * This rate is updated manually with elevated permissions. The new TPI doesn't take effect until after a cooldown.
 */
interface ITreasuryPriceIndexOracle is ITempleElevatedAccess {
    event TreasuryPriceIndexSet(uint96 oldTpi, uint96 newTpi);
    event TpiCooldownSet(uint32 cooldownSecs);
    event MaxTreasuryPriceIndexDeltaSet(uint256 maxDelta);

    error BreachedMaxTpiDelta(uint96 oldTpi, uint96 newTpi, uint256 maxDelta);

    /**
     * @notice The current Treasury Price Index (TPI) value
     * @dev If the TPI has just been updated, the old TPI will be used until `cooldownSecs` has elapsed
     */
    function treasuryPriceIndex() external view returns (uint96);

    /**
     * @notice The maximum allowed TPI change on any single `setTreasuryPriceIndex()`, in absolute terms.
     * @dev Used as a bound to avoid unintended/fat fingering when updating TPI
     */
    function maxTreasuryPriceIndexDelta() external view returns (uint256);

    /**
     * @notice The current internal TPI data along with when it was last reset, and the prior value
     */
    function tpiData() external view returns (
        uint96 currentTpi,
        uint96 previousTpi,
        uint32 lastUpdatedAt,
        uint32 cooldownSecs
    );

    /**
     * @notice Set the Treasury Price Index (TPI)
     */
    function setTreasuryPriceIndex(uint96 value) external;

    /**
     * @notice Set the number of seconds to elapse before a new TPI will take effect.
     */
    function setTpiCooldown(uint32 cooldownSecs) external;

    /**
     * @notice Set the maximum allowed TPI change on any single `setTreasuryPriceIndex()`, in absolute terms.
     * @dev 18 decimal places, 0.20e18 == $0.20
     */
    function setMaxTreasuryPriceIndexDelta(uint256 maxDelta) external;

    /**
     * @notice The decimal precision of Temple Price Index (TPI)
     * @dev 18 decimals, so 1.02e18 == $1.02
     */
    // solhint-disable-next-line func-name-mixedcase
    function TPI_DECIMALS() external view returns (uint256);
}