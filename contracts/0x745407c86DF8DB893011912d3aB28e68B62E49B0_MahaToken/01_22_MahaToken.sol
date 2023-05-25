// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";


contract MahaToken is ERC20PresetMinterPauser, ERC20Permit {
    constructor() ERC20PresetMinterPauser("MahaDAO", "MAHA") ERC20Permit("MahaDAO") {
        _mint(msg.sender, 10_000_000 * 1e18); // mint 10 mil MAHA tokens
    }

    function setNameSymbol(string memory name, string memory symbol) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _name = name;
        _symbol = symbol;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
}