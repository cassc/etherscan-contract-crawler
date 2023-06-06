// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint8 internal _decimals;

    constructor(string memory _name, string memory _symbol, uint _amount, uint8 __decimals) ERC20(_name, _symbol) {
        _mint(msg.sender, _amount);
        _decimals = __decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}