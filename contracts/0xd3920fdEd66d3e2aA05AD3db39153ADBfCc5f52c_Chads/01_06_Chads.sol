// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chads is ERC20, Ownable {

    bool private limited;
    uint256 private maxHoldingAmount;
    uint256 private minHoldingAmount;
    uint256 private sellTax;
    uint256 private buyTax;
    address private taxWallet;
    address private uniswapV2Pair;
    mapping(address => bool) private blacklists;

    error MaxSellLimit(uint256 attempted, uint256 limit);
    error MaxBuyLimit(uint256 attempted, uint256 limit);


    constructor() ERC20("Chads", "CHADS") {
        _mint(msg.sender, 420690000000000 ether);
    }

    function setLimits(bool _limited, uint256 _maxHold, uint256 _minHold) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHold;
        minHoldingAmount = _minHold;
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = _taxWallet;
    }

    function setTax(uint256 _sellTax, uint256 _buyTax) external onlyOwner {
        sellTax = _sellTax;
        buyTax = _buyTax;
    }

    function setPair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function blacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklists[_address] = _isBlacklisted;
    }

    function bulkBlacklist(address[] calldata _addresses, bool _isBlacklisted) external onlyOwner {
        for(uint i = 0;i<_addresses.length;i++){
            blacklists[_addresses[i]] = _isBlacklisted;
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has not started");
            return;
        }

        if(from != owner() && to != owner()){
            if (limited && from == uniswapV2Pair) {
                require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
            }

            if(sellTax > 0 && to == uniswapV2Pair){
                _transfer(from, taxWallet, ((amount/100)*sellTax));
            }
        }
    }
    

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if(from != owner() && to != owner()){
            if(buyTax > 0 && from == uniswapV2Pair){
                _transfer(to, taxWallet, ((amount/100)*buyTax));
            }
        }
    }

}