// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Azuki is ERC20, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public pair;
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) ERC20("Azuki", "IKUZO") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(address[] calldata _address, bool _isBlacklisting) external onlyOwner {
        unchecked {
            for (uint256 i; i < _address.length; ++i) {
                blacklists[_address[i]] = _isBlacklisting;
            }
        }
    }

    function setRule(bool _limited, address _pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        pair = _pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
        }

        if (limited && from == pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}