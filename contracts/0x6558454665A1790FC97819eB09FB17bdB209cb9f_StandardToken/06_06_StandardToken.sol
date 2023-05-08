// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StandardToken is Ownable, ERC20 {
    uint256 public constant VERSION = 1;

    // Max transaction amount, to prevent bots at the beginning
    uint256 public maxTransactionAmount;

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
        // Check max transaction amount
        if (from != owner() && to != owner() && maxTransactionAmount > 0) {
            require(amount <= maxTransactionAmount, "Max transfer amount exceeded");
        }
    }

    function setMaxTransferAmount(uint256 _maxTransferAmount) external onlyOwner {
        maxTransactionAmount = _maxTransferAmount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}