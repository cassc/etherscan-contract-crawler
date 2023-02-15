//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BLK is ERC20Burnable, Ownable, Pausable {
    using SafeMath for uint256;

    struct Account {
        uint lockedBalance;
        bool whitelisted;
        bool isShop;
        uint conversionRate;
    }

    mapping(address => Account) public accounts;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event AddedToShops(address indexed account);
    event RemovedFromShops(address indexed account);

    constructor() ERC20("Blockeras", "BLK") {
        addWhitelisted(0x0000000000000000000000000000000000000000);
        addWhitelisted(msg.sender);
    }

    function decimals() public pure override returns (uint8) {
		return 18;
	}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(accounts[from].whitelisted == true, "address from not whitelisted");
        require(accounts[to].whitelisted == true, "address to not whitelisted");
        require(to != from, "self transfer not enabled");
        if(accounts[to].isShop && from != address(0) ) {
            require(accounts[to].lockedBalance > amount, "shop lockedBalance under budget");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(accounts[to].isShop && from != address(0)) {
            uint unlockedBalance = amount.mul(accounts[to].conversionRate);
            require(accounts[to].lockedBalance > unlockedBalance, "locked balance not enough");
            accounts[to].lockedBalance -= unlockedBalance;
            _mint(to, unlockedBalance);
        }
        super._afterTokenTransfer(from, to, amount);
    }

    function addWhitelisted(address _addr) public onlyOwner {
        accounts[_addr].whitelisted = true;
        emit AddedToWhitelist(_addr);
    }

    function removeWhitelisted(address _addr) public onlyOwner {
        accounts[_addr].whitelisted = false;
        emit RemovedFromWhitelist(_addr);
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return accounts[_addr].whitelisted;
    }

    function addShop(address _addr) public onlyOwner {
        addWhitelisted(_addr);
        accounts[_addr].whitelisted = true;
        accounts[_addr].isShop = true;
        accounts[_addr].conversionRate = 2;
        emit AddedToShops(_addr);
    }

    function removeShop(address _addr) public onlyOwner {
        removeWhitelisted(_addr);
        accounts[_addr].isShop = false;
        accounts[_addr].conversionRate = 1;
        emit RemovedFromShops(_addr);
    }

    function isShop(address _addr) public view returns (bool) {
        return accounts[_addr].isShop;
    }

    function getConversionRate(address _addr) public view returns (uint) {
        return accounts[_addr].conversionRate;
    }

    function setConversionRate(address _addr, uint _rate) public onlyOwner returns (bool) {
        accounts[_addr].conversionRate = _rate;
        return true;
    }

    function balanceLockedOf(address _addr) public view returns (uint) {
        return accounts[_addr].lockedBalance;
    }

    function mintLocked(address _addr, uint amount) public onlyOwner returns (bool) {
        uint balance = accounts[_addr].lockedBalance;
        accounts[_addr].lockedBalance = balance.add(amount);
        return true;
    }
}