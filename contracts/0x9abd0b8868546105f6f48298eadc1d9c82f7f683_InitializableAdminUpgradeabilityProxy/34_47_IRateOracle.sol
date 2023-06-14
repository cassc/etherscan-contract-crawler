pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only



/**
 * @title Notional rate oracle interface
 * @notice Contracts implementing this interface are able to provide rates to the asset
 *  risk and valuation framework.
 */
interface IRateOracle {
    /* is IERC165 */
    /**
     * Returns the currently active maturities. Note that this may read state to confirm whether or not
     * the market for a maturity has been created.
     *
     * @return an array of the active maturity ids
     */
    function getActiveMaturities() external view returns (uint32[] memory);

    /**
     * Sets governance parameters on the rate oracle.
     *
     * @param cashGroupId this cannot change once set
     * @param instrumentId cannot change once set
     * @param precision will only take effect on a new maturity
     * @param maturityLength will take effect immediately, must be careful
     * @param numMaturities will take effect immediately, makers can create new markets
     * @param maxRate will take effect immediately
     */
    function setParameters(
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 precision,
        uint32 maturityLength,
        uint32 numMaturities,
        uint32 maxRate
    ) external;
}