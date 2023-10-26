// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;

// solhint-disable

library GyroECLPPoolErrors {
    // Input
    uint256 internal constant ADDRESS_IS_ZERO_ADDRESS = 120;
    uint256 internal constant TOKEN_IN_IS_NOT_TOKEN_0 = 121;

    // Math
    uint256 internal constant PRICE_BOUNDS_WRONG = 354;
    uint256 internal constant ROTATION_VECTOR_WRONG = 355;
    uint256 internal constant ROTATION_VECTOR_NOT_NORMALIZED = 356;
    uint256 internal constant ASSET_BOUNDS_EXCEEDED = 357;
    uint256 internal constant DERIVED_TAU_NOT_NORMALIZED = 358;
    uint256 internal constant DERIVED_ZETA_WRONG = 359;
    uint256 internal constant STRETCHING_FACTOR_WRONG = 360;
    uint256 internal constant DERIVED_UVWZ_WRONG = 361;
    uint256 internal constant INVARIANT_DENOMINATOR_WRONG = 362;
    uint256 internal constant MAX_ASSETS_EXCEEDED = 363;
    uint256 internal constant MAX_INVARIANT_EXCEEDED = 363;
    uint256 internal constant DERIVED_DSQ_WRONG = 364;
}