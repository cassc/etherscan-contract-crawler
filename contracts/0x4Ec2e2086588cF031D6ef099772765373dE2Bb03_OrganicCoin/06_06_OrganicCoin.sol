// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrganicCoin is Ownable, ERC20 {
    bool public tradingEnabled;
    bool public dexLimited;
    uint256 public dexMinBalance;
    uint256 public dexMaxBalance;
    address public dexAddress;
    mapping(address => bool) public blacklisted;

    constructor(uint256 _totalSupply) ERC20("OrganicCoin", "ORGN") {
        _mint(msg.sender, _totalSupply*10**18);
    }

    function _beforeTokenTransfer(address from,address to, uint256 amount) 
    override 
    internal 
    virtual {
        require(!blacklisted[to] && !blacklisted[from], "Address blacklisted");

        if (!tradingEnabled && to != address(0)) {
            require(from == owner() || to == owner(), "Trading disabled");
            return;
        }

        if (dexLimited && from == dexAddress) {
            require(super.balanceOf(to) + amount >= dexMinBalance && super.balanceOf(to) + amount <= dexMaxBalance, "Disallowed balance reached");
        }
    }

    function enableTrading(bool _enabled) 
    external 
    onlyOwner {
        tradingEnabled = _enabled;
    }

    function configureDexTrading(bool _dexLimited, address _dexAddress, uint256 _dexMinBalance, uint256 _dexMaxBalance) 
    external 
    onlyOwner {
        dexLimited = _dexLimited;
        dexAddress = _dexAddress;
        dexMinBalance = _dexMinBalance;
        dexMaxBalance = _dexMaxBalance;
    }

    function blacklist(address _address, bool _isBlacklisted) 
    external 
    onlyOwner {
        blacklisted[_address] = _isBlacklisted;
    }

    function burn(uint256 value) 
    external {
        _burn(msg.sender, value);
    }
}