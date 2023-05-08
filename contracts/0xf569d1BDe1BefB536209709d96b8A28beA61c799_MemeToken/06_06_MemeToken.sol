// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeToken is Ownable, ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1 * (10 ** 12) * (10 ** 18); // 1 trillion tokens
    mapping(address => bool) public blacklists;
    uint256 public maxTransferAmount;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[from] && !blacklists[to]); // Blacklist address

        if (from != owner() && to != owner() && maxTransferAmount > 0) {
            require(amount <= maxTransferAmount); // Transfer amount exceeds the max transfer amount
        }
    }

    function setBlacklist(
        address _address,
        bool isBlacklist
    ) external onlyOwner {
        blacklists[_address] = isBlacklist;
    }

    function setMaxTransferAmount(
        uint256 _maxTransferAmount
    ) external onlyOwner {
        maxTransferAmount = _maxTransferAmount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}