// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @notice  This ERC20 contract represents the Zivoe ($ZVE) token.
///          This contract should support the following functionalities:
///           - Burnable
///           - Fixed supply of 25,000,000 $ZVE.
///           - Facilitates voting by inheriting the ERC20Votes module.
contract ZivoeToken is ERC20Votes {
    
    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeToken contract ($ZVE).
    /// @param  name_   The name of $ZVE (Zivoe).
    /// @param  symbol_ The symbol of $ZVE (ZVE).
    /// @param  init    The initial address to escrow $ZVE supply, prior to distribution.
    constructor(string memory name_, string memory symbol_, address init) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(init, 25000000 ether);
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Burns $ZVE tokens.
    /// @param  amount The number of $ZVE tokens to burn.
    function burn(uint256 amount) public virtual { _burn(_msgSender(), amount); }
    
}