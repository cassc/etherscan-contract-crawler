// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    /// @param name_ Token name.
    /// @param symbol_ Token symbol.
    /// @param initialSupply_ Initial supply.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) 
        ERC20(name_, symbol_) 
    {
        _mint(msg.sender, initialSupply_);
    }
}