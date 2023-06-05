// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title Instrumental Token ERC20 token contract
contract STRM is ERC20Permit {
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(msg.sender, totalSupply_);
    }

}