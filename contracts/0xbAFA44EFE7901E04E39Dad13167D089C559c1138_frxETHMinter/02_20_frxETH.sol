// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================== frxETH ==============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jack Corddry: https://github.com/corddry
// Nader Ghazvini: https://github.com/amirnader-ghazvini 

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian
// Dennis: https://github.com/denett
// Travis Moore: https://github.com/FortisFortuna
// Jamie Turley: https://github.com/jyturley

/// @title Stablecoin pegged to Ether for use within the Frax ecosystem
/** @notice Does not accrue ETH 2.0 staking yield: it must be staked at the sfrxETH contract first.
    ETH -> frxETH conversion is permanent, so a market will develop for the latter.
    Withdraws are not live (as of deploy time) so loosely pegged to eth but is possible will float */
/// @dev frxETH adheres to EIP-712/EIP-2612 and can use permits
import { ERC20PermitPermissionedMint } from "./ERC20/ERC20PermitPermissionedMint.sol";

contract frxETH is ERC20PermitPermissionedMint {

    /* ========== CONSTRUCTOR ========== */
    constructor(
      address _creator_address,
      address _timelock_address
    ) 
    ERC20PermitPermissionedMint(_creator_address, _timelock_address, "Frax Ether", "frxETH") 
    {}

}