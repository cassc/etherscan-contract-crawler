// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { ERC20 } from "../ERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}