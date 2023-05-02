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
// ================ FraxlendPairAccessControlErrors ===================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

/// @title FraxlendPairAccessControlErrors
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract contract which contains the errors for the Access Control contract
abstract contract FraxlendPairAccessControlErrors {
    error OnlyProtocolOrOwner();
    error OnlyTimelockOrOwner();
    error ExceedsBorrowLimit();
    error AccessControlRevoked();
    error RepayPaused();
    error ExceedsDepositLimit();
    error WithdrawPaused();
    error LiquidatePaused();
    error InterestPaused();
}