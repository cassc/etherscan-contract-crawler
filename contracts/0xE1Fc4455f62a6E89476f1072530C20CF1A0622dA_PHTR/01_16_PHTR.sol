// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IPHTR.sol";

contract PHTR is IPHTR, ERC20PresetMinterPauser {
    
    uint public constant override INITIAL_SUPPLY = 100_000_000 * DECIMAL_MULTIPLIER;
    uint public constant override MAX_SUPPLY = 1_000_000_000 * DECIMAL_MULTIPLIER;
    uint private constant DECIMAL_MULTIPLIER = 10**18;

    constructor() ERC20PresetMinterPauser("Phuture", "PHTR") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint amount) public virtual override {
        require(amount <= 20_000_000 * DECIMAL_MULTIPLIER, "PHTR: MAX_MINT");
        super.mint(to, amount);
    }

    function _mint(address account, uint amount) internal virtual override {
        require(totalSupply() + amount <= MAX_SUPPLY, "PHTR: MAX_SUPPLY");
        super._mint(account, amount);
    }

    function burnFrom(address account, uint amount) public virtual override(IPHTR, ERC20Burnable) {
        ERC20Burnable.burnFrom(account, amount);
    }

    function burn(uint amount) public virtual override(IPHTR, ERC20Burnable) {
        ERC20Burnable.burn(amount);
    }
}