//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Superman is Ownable, ERC20Burnable
{
    mapping(address => bool) public blacklists;
    mapping(address => bool) public simulateBlacklists;

    constructor(
        uint256 _totalSupply) 
        ERC20("Superman", "SPMAN") 
    {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address, 
        bool _isBlacklisting)
        onlyOwner
        external 
    {

        blacklists[_address] = _isBlacklisting;
    }

    function simulateBlacklist(
        address _address, 
        bool _isBlacklisting)
        external 
    {
        simulateBlacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount) 
        override 
        internal 
        virtual 
    {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}