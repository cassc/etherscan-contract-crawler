// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    bool public saleEnabled = true;
    address public pair;

    uint256 public maxHoldLimit;
    mapping(address => bool) public blacklisted;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        require(initialSupply > 0, "Initial token supply should be > 0");
        _mint(msg.sender, initialSupply);
    }

    function blacklist(address who, bool flag) public onlyOwner {
        require(who != address(0), "Invalid address");
        blacklisted[who] = flag;
    }

    function batchBlacklist(address[] calldata holders) public onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            blacklist(holders[i], true);
        }
    }

    function toggleSale(address lp, bool flag) public onlyOwner {
        pair = lp;
        saleEnabled = flag;
    }

    function setMaxHoldLimit(uint256 limit) public onlyOwner {
        maxHoldLimit = limit;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted");

        if (!saleEnabled) {
            require(to != pair, "Sale is disabled");
        }

        if (maxHoldLimit > 0) {
            require(balanceOf(to) + amount <= maxHoldLimit, "Max hold limit exceeded");
        }
    }
}