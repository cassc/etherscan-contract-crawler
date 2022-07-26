// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20Spendable is ERC20PresetMinterPauser {

    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {}

    function spend(address spender, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to spend");
        _burn(spender, amount);
    }
}