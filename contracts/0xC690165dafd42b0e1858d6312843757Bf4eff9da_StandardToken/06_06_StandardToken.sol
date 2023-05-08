// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StandardToken is Ownable, ERC20 {
    // Max transaction amount, to prevent bots
    uint256 public maxTransAmount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply * (10 ** decimals()));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (maxTransAmount > 0 && from != owner() && to != owner()) {
            // Check max transaction amount
            require(amount <= maxTransAmount, "Max transfer amount exceeded");
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setMaxTransferAmount(uint256 _maxTransAmount) external onlyOwner {
        maxTransAmount = _maxTransAmount;
    }
}