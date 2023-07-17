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
// ========================= SfrxEthFraxOracle ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Jon Walch: https://github.com/jonwalch

// Reviewers
// Drake Evans: https://github.com/DrakeEvans
// Dennis: https://github.com/denett

// ====================================================================
import { FraxOracle, ConstructorParams as FraxOracleParams } from "src/abstracts/FraxOracle.sol";

/// @title SfrxEthFraxOracle
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice Drop in replacement for a chainlink oracle for price of sfrxEth in ETH
contract SfrxEthFraxOracle is FraxOracle {
    constructor(FraxOracleParams memory _params) FraxOracle(_params) {}

    // ====================================================================
    // View Helpers
    // ====================================================================

    /// @notice The ```description``` function returns the description of the contract
    /// @return _description The description of the contract
    function description() external pure override returns (string memory _description) {
        _description = "sfrxEth/ETH";
    }
}