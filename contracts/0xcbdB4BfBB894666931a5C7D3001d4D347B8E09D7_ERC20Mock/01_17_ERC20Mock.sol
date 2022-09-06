// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20Mock is ERC20PresetMinterPauser {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimalsValue
    ) ERC20PresetMinterPauser(name, symbol) {
        _decimals = decimalsValue;
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _mint(_msgSender(), 10000000 * (10**decimalsValue));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}