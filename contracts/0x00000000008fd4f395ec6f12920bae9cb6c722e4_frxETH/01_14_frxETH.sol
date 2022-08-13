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
// Dennett: https://github.com/denett
// Travis Moore: https://github.com/FortisFortuna

import "./ERC20/ERC20PermitPermissionedMint.sol";

contract frxETH is ERC20PermitPermissionedMint {

    /* ========== CONSTRUCTOR ========== */
    constructor(
      address _creator_address,
      address _timelock_address
    ) 
    ERC20PermitPermissionedMint(_creator_address, _timelock_address, "Frax Ethereum", "frxETH") 
    {}

}