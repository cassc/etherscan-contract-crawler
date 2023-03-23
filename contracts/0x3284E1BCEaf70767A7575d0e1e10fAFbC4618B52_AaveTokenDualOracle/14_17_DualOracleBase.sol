// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== DualOracleBase ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================

import "../../interfaces/IDualOracle.sol";

struct ConstructorParams {
    address baseToken0;
    uint8 baseToken0Decimals;
    address quoteToken0;
    uint8 quoteToken0Decimals;
    address baseToken1;
    uint8 baseToken1Decimals;
    address quoteToken1;
    uint8 quoteToken1Decimals;
}

/// @title DualOracleBase
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  Base Contract for Frax Dual Oracles
abstract contract DualOracleBase is IDualOracle {
    /// @notice The precision of the oracle
    uint256 public constant ORACLE_PRECISION = 1e18;

    /// @notice The first quote token
    address public immutable QUOTE_TOKEN_0;

    /// @notice The first quote token decimals
    uint256 public immutable QUOTE_TOKEN_0_DECIMALS;

    /// @notice The second quote token
    address public immutable QUOTE_TOKEN_1;

    /// @notice The second quote token decimals
    uint256 public immutable QUOTE_TOKEN_1_DECIMALS;

    /// @notice The first base token
    address public immutable BASE_TOKEN_0;

    /// @notice The first base token decimals
    uint256 public immutable BASE_TOKEN_0_DECIMALS;

    /// @notice The second base token
    address public immutable BASE_TOKEN_1;

    /// @notice The second base token decimals
    uint256 public immutable BASE_TOKEN_1_DECIMALS;

    /// @notice The first normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_0;

    /// @notice The second normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_1;

    constructor(ConstructorParams memory _params) {
        QUOTE_TOKEN_0 = _params.quoteToken0;
        QUOTE_TOKEN_0_DECIMALS = _params.quoteToken0Decimals;
        QUOTE_TOKEN_1 = _params.quoteToken1;
        QUOTE_TOKEN_1_DECIMALS = _params.quoteToken1Decimals;
        BASE_TOKEN_0 = _params.baseToken0;
        BASE_TOKEN_0_DECIMALS = _params.baseToken0Decimals;
        BASE_TOKEN_1 = _params.baseToken1;
        BASE_TOKEN_1_DECIMALS = _params.baseToken1Decimals;
        NORMALIZATION_0 = int256(QUOTE_TOKEN_0_DECIMALS) - int256(BASE_TOKEN_0_DECIMALS);
        NORMALIZATION_1 = int256(QUOTE_TOKEN_1_DECIMALS) - int256(BASE_TOKEN_1_DECIMALS);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function decimals() external pure returns (uint8) {
        return 18;
    }
}