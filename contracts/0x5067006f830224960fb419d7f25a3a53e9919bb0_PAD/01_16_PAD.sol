// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IPAD.sol";

contract PAD is IPAD, ERC20PresetMinterPauser {
    
    uint public constant override INITIAL_SUPPLY = 80_000_000 * DECIMAL_MULTIPLIER;
    uint public constant override MAX_SUPPLY = 1_000_000_000 * DECIMAL_MULTIPLIER;
    uint private constant DECIMAL_MULTIPLIER = 10**18;

    constructor() ERC20PresetMinterPauser("PAD", "PAD") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply() + amount <= MAX_SUPPLY, "PAD: MAX_SUPPLY");
        super._mint(account, amount);
    }
}