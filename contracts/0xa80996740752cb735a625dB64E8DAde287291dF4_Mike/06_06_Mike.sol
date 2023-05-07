// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Mike is Ownable, ERC20 {
    uint8 public tradingStarted;
    // 69T
    uint256 public MAX_SUPPLY = 69000000000000 * 10 ** 18;
    mapping(address => bool) public blacklists;

    constructor() ERC20("Mike", "MIKE") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setTradingStarted(uint8 _tradingStarted) external onlyOwner {
        tradingStarted = _tradingStarted;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        if (tradingStarted == 0) {
            require(from == owner() || to == owner(), "Trading is not started");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}