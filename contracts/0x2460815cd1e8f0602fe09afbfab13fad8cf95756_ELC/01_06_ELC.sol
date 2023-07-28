// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ELC is ERC20, Ownable {
    // manage holding limit for equitable distribution on deployment
    uint256 public maxHoldingAmount = 1_000_000_000 * 10 ** decimals();

    constructor() ERC20("Eloncoin", "ELC") {
        _mint(msg.sender, 1_000_000_000_000 * 10 ** decimals());
    }

    function setMaxHoldingAmount(uint256 _maxHoldingAmount) external onlyOwner {
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(from == owner() || to == owner() || super.balanceOf(to) + amount <= maxHoldingAmount, "Exceeds holding limit");
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}