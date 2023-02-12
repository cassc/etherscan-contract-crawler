// contracts/MGUToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "ERC20Burnable.sol";

contract MGUToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MetaGreenUniverse", "MGU") {
        _mint(msg.sender, initialSupply);
    }
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}