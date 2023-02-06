// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract LockedXMON is ERC20, Owned {
    constructor(uint8 _decimals) ERC20("LOCKED XMON", "lXMON", _decimals) Owned(msg.sender) {}

    function mint(address to, uint256 value) external onlyOwner {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external onlyOwner {
        _burn(from, value);
    }
}