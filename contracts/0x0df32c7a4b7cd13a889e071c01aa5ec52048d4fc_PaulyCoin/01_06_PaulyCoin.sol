// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaulyCoin is ERC20, Ownable {
    bool public limited;
    uint256 public maxAmount;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Pauly Coin", "PC") {
        _mint(0xBa7B47Eca6e45f74586789af3F7Af40DD01BFdba, 1000000000000 * 1e18);
        limited = true;
        maxAmount = 10000000000 * 1e18;
    }

    function removeLimit() public onlyOwner {
        limited = false;
    }

    function blacklist(address[] memory addr) public onlyOwner {
        for(uint256 i = 0; i < addr.length; i++) {
            blacklists[addr[i]] = true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "not allowed");
        if (limited) {
            require(balanceOf(to) + amount <= maxAmount, "max amount");
        }
    }

}