// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PreICO is ERC20 {
    uint256 constant private _totalSupply = 1191750000 * 1e18; // 1.5B
    uint8 constant private _decimals = 18;
    string constant private _name = 'KOSYS PreICO Token';
    string constant private _symbol = 'KOS-PreICO';

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }
}