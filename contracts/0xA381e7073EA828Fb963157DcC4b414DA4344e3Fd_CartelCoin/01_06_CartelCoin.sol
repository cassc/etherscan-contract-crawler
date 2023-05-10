// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 *    $$\     $$$$$$\   $$$$$$\  $$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$\
 *  $$$$$$\  $$  __$$\ $$  __$$\ $$  __$$\\__$$  __|$$  _____|$$ |
 * $$  __$$\ $$ /  \__|$$ /  $$ |$$ |  $$ |  $$ |   $$ |      $$ |
 * $$ /  \__|$$ |      $$$$$$$$ |$$$$$$$  |  $$ |   $$$$$\    $$ |
 * \$$$$$$\  $$ |      $$  __$$ |$$  __$$<   $$ |   $$  __|   $$ |
 *  \___ $$\ $$ |  $$\ $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$ |
 * $$\  \$$ |\$$$$$$  |$$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ $$$$$$$$\
 * \$$$$$$  | \______/ \__|  \__|\__|  \__|  \__|   \________|\________|
 *  \_$$  _/
 *    \ _/
 *
 * https://twitter.com/cartelcoin_eth
 * https://t.me/cartelcoineth
 */
contract CartelCoin is ERC20, Ownable {
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

    function setMaxHoldLimit(uint256 limit) public onlyOwner {
        maxHoldLimit = limit;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklisted[from] && !blacklisted[to], "Blacklisted");

        if (maxHoldLimit > 0) {
            require(balanceOf(to) + amount <= maxHoldLimit, "Max hold limit exceeded");
        }
    }
}
