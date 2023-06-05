// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IFeeProvider.sol";
import "../interfaces/IPoolRegistry.sol";
import "../interfaces/external/IESMET.sol";

abstract contract FeeProviderStorageV1 is IFeeProvider {
    struct Tier {
        uint128 min; // esMET min balance needed to be eligible for `discount`
        uint128 discount; // discount in percentage to apply. Use 18 decimals (e.g. 1e16 = 1%)
    }

    /**
     * @notice The fee discount tiers
     */
    Tier[] public tiers;

    /**
     * @notice The default fee charged when swapping synthetic tokens
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override defaultSwapFee;

    /**
     * @notice The fee charged when depositing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override depositFee;

    /**
     * @notice The fee charged when minting a synthetic token
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override issueFee;

    /**
     * @notice The fee charged when withdrawing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override withdrawFee;

    /**
     * @notice The fee charged when repaying debt
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override repayFee;

    /**
     * @notice The fees charged when liquidating a position
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    LiquidationFees public override liquidationFees;

    /**
     * @dev The Pool Registry
     */
    IPoolRegistry public poolRegistry;

    /**
     * @notice The esMET contract
     */
    IESMET public esMET;
}