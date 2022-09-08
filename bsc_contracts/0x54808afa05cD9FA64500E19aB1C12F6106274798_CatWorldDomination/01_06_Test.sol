// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CatWorldDomination is ERC20, Ownable {
    //public
    uint256 constant public MAX_BUY_TAX = 5;
    uint256 constant public MAX_SELL_TAX = 5;
    uint256 constant public MAX_WALLET = 1;

    uint256 immutable public maxSupply;

    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    
    //private
    mapping(address => bool) private _banned;

    constructor() ERC20("CatWorldDomination", "CWD") {
        maxSupply = 10 ** 9 * 10 ** decimals();
        _mint(msg.sender, maxSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    // BlackList module
    function ban(address toBan) public onlyOwner() {
        require(!_banned[toBan], "Account already banned");
        _banned[toBan] = true;
    }

    function isBanned(address account) public view returns(bool) {
        return _banned[account];
    }

    // Tax module
    function changeBuyTax(uint256 newTax) public onlyOwner() {
        require(newTax <= MAX_BUY_TAX, "New tax cannot exceed MAX_BUY_TAX");
        buyTax = newTax;
    }

    function changeSellTax(uint256 newTax) public onlyOwner() {
        require(newTax <= MAX_SELL_TAX, "New tax cannot exceed MAX_SELL_TAX");
        sellTax = newTax;
    }

	// Hooks
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!_banned[from] && !_banned[to], "Account banned.");
        require(totalSupply() + amount <= maxSupply, "Cannot exceed _maxSupply.");
        //require(totalSupply() * MAX_WALLET / 100 >= balanceOf(to) + amount, "Account would exceed MAX_WALLET");
    }
}