// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IFixedStrikeOptionTeller} from "src/interfaces/IFixedStrikeOptionTeller.sol";
import {OLM, ManualStrikeOLM, OracleStrikeOLM} from "src/fixed-strike/liquidity-mining/OLM.sol";

/* ========== ERRORS ========== */
error Factory_InvalidStyle();

/// @dev The OLM Factory contracts allows anyone to deploy new OLM contracts. When deployed, the owner of the OLM is set to the caller.
///      There are two OLM implementations available in the factory: Manual Strike and Oracle Strike. This factory deploys Manual Strike OLMs.
///      See OLM.sol for details on the different implementations.
///      Manual Strike: Owners must manually update the strike price to change it over time
///      Oracle Strike: Strike price is automatically updated based on an oracle and discount.
///      A minimum strike price can be set on the Oracle Strike version to prevent it from going too low.

/// @title Manual Strike Option Liquidity Mining (OLM) Factory
/// @notice Factory for deploying Manual Strike OLM contracts
/// @author Bond Protocol
contract MOLMFactory {
    /* ========== STATE VARIABLES ========== */

    /// @notice Option Teller to be used by OLM contracts
    IFixedStrikeOptionTeller public immutable optionTeller;

    /* ========== CONSTRUCTOR ========== */

    constructor(IFixedStrikeOptionTeller optionTeller_) {
        optionTeller = optionTeller_;
    }

    /* ========== DEPLOY Manual Strike OLM CONTRACTS ========== */

    /// @notice Deploy a new Manual Strike OLM contract with the caller as the owner
    /// @param stakedToken_  ERC20 token that will be staked to earn rewards
    /// @param payoutToken_  ERC20 token that stakers will receive call options for
    /// @return              Address of the new OLM contract
    function deploy(ERC20 stakedToken_, ERC20 payoutToken_) external returns (ManualStrikeOLM) {
        return new ManualStrikeOLM(msg.sender, stakedToken_, optionTeller, payoutToken_);
    }
}

/// @title Oracle Strike Option Liquidity Mining (OLM) Factory
/// @notice Factory for deploying Oracle Strike OLM contracts
/// @author Bond Protocol
contract OOLMFactory {
    /* ========== STATE VARIABLES ========== */

    /// @notice Option Teller to be used by OLM contracts
    IFixedStrikeOptionTeller public immutable optionTeller;

    /* ========== CONSTRUCTOR ========== */

    constructor(IFixedStrikeOptionTeller optionTeller_) {
        optionTeller = optionTeller_;
    }

    /* ========== DEPLOY Oracle Strike OLM CONTRACTS ========== */

    /// @notice Deploy a new Oracle Strike OLM contract with the caller as the owner
    /// @param stakedToken_  ERC20 token that will be staked to earn rewards
    /// @param payoutToken_  ERC20 token that stakers will receive call options for
    /// @return              Address of the new OLM contract
    function deploy(ERC20 stakedToken_, ERC20 payoutToken_) external returns (OracleStrikeOLM) {
        return new OracleStrikeOLM(msg.sender, stakedToken_, optionTeller, payoutToken_);
    }
}