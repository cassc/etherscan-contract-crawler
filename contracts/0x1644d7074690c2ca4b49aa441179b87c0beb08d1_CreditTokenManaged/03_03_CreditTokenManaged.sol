// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract CreditTokenManaged is Owned, ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) Owned(msg.sender) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burnAddress(address target) public onlyOwner {
        _burn(target, balanceOf[target]);
    }

}