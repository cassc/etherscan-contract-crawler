// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC20/ERC20.sol";
import "./token/ERC20/extensions/ERC20Burnable.sol";
import "./security/Pausable.sol";
import "./security/ReentrancyGuard.sol";
import "./access/Ownable.sol";
import "./utils/math/SafeMath.sol";
import "./token/ERC20/extensions/draft-ERC20Permit.sol";


contract ZOLODAO is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit, ReentrancyGuard {
    constructor() ERC20("ZOLODIA DAO", "ZOLODAO") ERC20Permit("ZOLODAO") {
    }
    using SafeMath for uint256;
    bool public public_mint_open = true;
    uint256 public mint_price = 600000000000000;
    uint256 public max_mint_allowed = 1000000;
    uint256 public min_mint_allowed = 100;
    uint256 private constant stake_per_token = 4000000000000;

    function setPrice(uint256 _mint_price) public onlyOwner {                
        mint_price = _mint_price;
    }

    function setSettings(bool _public_mint_open,uint256 _mint_price, uint256 _max_mint_allowed, uint256 _min_mint_allowed) public onlyOwner {                
        public_mint_open = _public_mint_open;
        mint_price = _mint_price;
        max_mint_allowed = _max_mint_allowed;
        min_mint_allowed = _min_mint_allowed;
    }

    function mintDAO(address _to, uint256 _quantity) public payable nonReentrant {
        require(_quantity > 0);
        if(owner() != msg.sender){
        require(public_mint_open);
        require(_quantity >= min_mint_allowed);
        require(_quantity <= max_mint_allowed);
        require(mint_price.mul(_quantity) <= msg.value);
        }
        _mint(_to, _quantity.mul(stake_per_token));

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function withdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}