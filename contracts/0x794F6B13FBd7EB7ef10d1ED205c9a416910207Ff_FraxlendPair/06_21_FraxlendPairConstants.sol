// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ===================== FraxlendPairConstants ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

abstract contract FraxlendPairConstants {
    // ============================================================================================
    // Constants
    // ============================================================================================

    // Precision settings
    uint256 internal constant LTV_PRECISION = 1e5; // 5 decimals
    uint256 internal constant LIQ_PRECISION = 1e5;
    uint256 internal constant UTIL_PREC = 1e5;
    uint256 internal constant FEE_PRECISION = 1e5;
    uint256 internal constant EXCHANGE_PRECISION = 1e18;

    // Default Interest Rate (if borrows = 0)
    uint64 internal constant DEFAULT_INT = 158049988; // 0.5% annual rate 1e18 precision

    // Protocol Fee
    uint16 internal constant DEFAULT_PROTOCOL_FEE = 0; // 1e5 precision
    uint256 internal constant MAX_PROTOCOL_FEE = 5e4; // 50% 1e5 precision

    error Insolvent(uint256 _borrow, uint256 _collateral, uint256 _exchangeRate);
    error BorrowerSolvent();
    error OnlyApprovedBorrowers();
    error OnlyApprovedLenders();
    error PastMaturity();
    error ProtocolOrOwnerOnly();
    error OracleLTEZero(address _oracle);
    error InsufficientAssetsInContract(uint256 _assets, uint256 _request);
    error NotOnWhitelist(address _address);
    error NotDeployer();
    error NameEmpty();
    error AlreadyInitialized();
    error SlippageTooHigh(uint256 _minOut, uint256 _actual);
    error BadSwapper();
    error InvalidPath(address _expected, address _actual);
    error BadProtocolFee();
    error BorrowerWhitelistRequired();
    error OnlyTimeLock();
    error PriceTooLarge();
    error PastDeadline(uint256 _blockTimestamp, uint256 _deadline);
}