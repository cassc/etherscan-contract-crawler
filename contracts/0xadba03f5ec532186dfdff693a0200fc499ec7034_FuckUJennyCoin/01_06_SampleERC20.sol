// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckUJennyCoin is ERC20, Ownable {
    address public taxWallet = 0xE8A5FaDc3f09DB7C10B2c34072cc338FeEEe75a7;
    uint256 public taxPercentage = 1;

    mapping(address => bool) public blacklist;

    event Blacklisted(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    constructor() ERC20("Fuck u Jenny", "FUJ") {
        uint256 totalSupply = 20110826 * (10**decimals());
        _mint(msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(!blacklist[msg.sender], "You are blacklisted");

        uint256 taxAmount = (value * taxPercentage) / 100;
        uint256 afterTaxAmount = value - taxAmount;

        _transfer(msg.sender, to, afterTaxAmount);
        _transfer(msg.sender, taxWallet, taxAmount);

        return true;
    }

    function addToBlacklist(address account) public onlyOwner {
        blacklist[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }
}