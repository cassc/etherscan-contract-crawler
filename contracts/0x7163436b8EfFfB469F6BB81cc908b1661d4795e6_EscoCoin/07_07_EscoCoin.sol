// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EscoCoin is ERC20, ERC20Burnable, Ownable {
    uint256 private DEV_WALLET_PERCENTAGE = 7;
    uint256 private TOTAL_PERCENTAGE = 100;

    mapping(address => bool) public blacklists;

    constructor(address devAddress) ERC20("Esco coin", "ESCO") {
        uint256 totalSupply = 330_000_000_000_000 ether;
        uint256 devFee = (totalSupply * DEV_WALLET_PERCENTAGE) /
            TOTAL_PERCENTAGE;
        _mint(devAddress, devFee);
        _mint(msg.sender, totalSupply - devFee);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}