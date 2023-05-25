// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IHAPI.sol";

contract HAPI is IHAPI, ERC20PresetMinterPauser {
    
    uint public constant override INITIAL_SUPPLY = 100000 * DECIMAL_MULTIPLIER;
    uint public constant override MAX_SUPPLY = 1000000 * DECIMAL_MULTIPLIER;
    uint constant private DECIMAL_MULTIPLIER = 10**18;

    constructor() ERC20PresetMinterPauser("HAPI", "HAPI") public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply().add(amount) <= MAX_SUPPLY, 'HAPI: MAX_SUPPLY');
        super._mint(account, amount);
    }
}