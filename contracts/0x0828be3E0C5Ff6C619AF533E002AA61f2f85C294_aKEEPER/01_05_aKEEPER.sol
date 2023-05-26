// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract aKEEPER is ERC20 {
    
    constructor() ERC20("Alpha Keeper", "aKEEPER") {
        _setupDecimals(9);
        _mint(msg.sender, 220000000000000);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}