// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract PEPE30 is ERC20, Ownable {
    mapping(address => bool) public _whitelist;
    uint256 public maxPerWallet;

    constructor() ERC20("PEPE 3.0", "PEPE 3.0") {
        _whitelist[msg.sender] = true;
        _mint(msg.sender, 69_000_000_000 * 1e18);
        maxPerWallet = (totalSupply() * 2) / 100;
    }

    function whitelist(address who) external onlyOwner {
        _whitelist[who] = true;
    }

    function burn(uint256 amt) external {
        require(_whitelist[msg.sender]);
        _burn(msg.sender, amt);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == owner()) return;
        if (!_whitelist[to]) {
            // no more than 3% of the supply per wallet
            require(balanceOf(to) + amount < maxPerWallet, "max wallet");
        }
    }
}