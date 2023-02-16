// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MasaToken is ERC20PresetMinterPauser {
    constructor(address admin) ERC20PresetMinterPauser("Masa Token", "MASA") {
        // mint supply of 1,588,866,523
        uint256 initialSupply = 1_588_866_523 * (10 ** uint256(decimals()));
        _mint(admin, initialSupply);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);

        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        renounceRole(MINTER_ROLE, _msgSender());
        renounceRole(PAUSER_ROLE, _msgSender());
    }
}