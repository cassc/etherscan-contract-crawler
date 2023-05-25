// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC20 contract with supply cap
 * @dev See {ERC20Capped}
 */
contract ClinTex is ERC20Capped, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap
    ) ERC20Capped(cap) ERC20(name, symbol) {}

    /// @dev See {ERC20Capped-_mint}
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}