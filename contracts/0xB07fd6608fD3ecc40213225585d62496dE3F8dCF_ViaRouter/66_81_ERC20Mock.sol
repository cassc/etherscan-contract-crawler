// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20Mock is ERC20PresetMinterPauser, ERC20Permit {
    constructor(string memory name_, string memory symbol_)
        ERC20PresetMinterPauser(name_, symbol_)
        ERC20Permit(name_)
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
}