// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/extensions/draft-ERC20Permit.sol";

contract OceanGate is ERC20, Ownable, ERC20Permit {
    constructor(string memory name_,
        string memory symbol_,
        uint256 initialBalance_) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(msg.sender, initialBalance_);
    }
}