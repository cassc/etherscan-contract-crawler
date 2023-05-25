// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RubicToken is ERC20Burnable, ERC20Capped, Ownable{
    constructor() ERC20("RUBIC TOKEN", "RBC") ERC20Capped(1_000_000_000 ether) {}

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}