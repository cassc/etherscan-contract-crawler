// SPDX-License-Identifier: MIT

/*
==== CONTRACT FUNCTIONS ==== 

1. Airdrop (pre-saler tokens distribution)
2. Blacklist (anti-bots)
4. 8/8 tax for 3 mins
5. 1.5% of total supply holding limit for 15 mins
6. Burn tokens
*/

pragma solidity ^0.8.0;

import { ERC20 } from "./2.ERC20.sol";
import { Ownable } from "./3.Ownable.sol";

 
// ==== Contract definition =====
contract RICHUNCLE is Ownable, ERC20 {

    // ==== Variables declaration ====
        // ==== LP-related variables ====
        address public uniswapContractAddress;
        uint256 public tradingStartTime;

        // ===== Whale prevention-related variables
        bool public holdLimitState = false;
        uint256 public holdLimitAmount;
        uint256 public holdLimitWindow = 15 minutes;

        // ===== Tax-related variables ====
        address public taxWallet;
        uint256 public initialTaxWindow = 3 minutes;
        uint256 public taxRate = 8;
        
        // ===== BL address mapping ====
        mapping(address => bool) public blacklisted;

       
    // ==== Constructor definition (Sets total supply & tax wallet address ====
    constructor(uint256 _totalSupply, address _taxWallet) ERC20("RICH UNCLE", "RICHU") { 
        _mint(msg.sender, _totalSupply);
        taxWallet = _taxWallet;
        holdLimitAmount = _totalSupply * 15 / 1000;
    
    }

    // ==== Burn token function ====
    function burn(uint256 value) public {
    _burn(msg.sender, value);
    }


    // ==== Token airdrop function ====
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner   {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }

    // ==== Set holding limit ====
    function setHoldLimit (bool _holdLimitState, uint256 _holdLimitAmount, uint256 _holdLimitWindow) external onlyOwner   {
        holdLimitState = _holdLimitState;
        holdLimitAmount = _holdLimitAmount;
        holdLimitWindow = _holdLimitWindow;
    }

    // ==== BL function ====
    function blacklist(address[] calldata _address, bool _isBlacklisted) external onlyOwner   {
        for (uint256 i = 0; i < _address.length; i++) {
            blacklisted[_address[i]] = _isBlacklisted;
        }
    }

    // ==== set Uniswap V2 Pair address ====
    function setUniswapContractAddress(address _uniswapContractAddress) external onlyOwner   {
        require(tradingStartTime == 0, "Can only set pair once.");
        uniswapContractAddress = _uniswapContractAddress;
        tradingStartTime = block.timestamp;
        holdLimitState = true;
    }
    
    // ==== Token transfer logic ====
   function _transfer(
    address from, 
    address to, 
    uint256 amount
    ) internal virtual override {
        // Calculate transfer and tax amounts
        uint256 taxAmount;
        uint256 transferAmount;

        if ((from == uniswapContractAddress || to == uniswapContractAddress) && (block.timestamp - tradingStartTime <= initialTaxWindow)) { // if within initial tax period
            taxAmount = (amount * taxRate) / 100;  // Calculate amount of tokens to be taxed based on initial tax rate
            transferAmount = amount - taxAmount;
             
            //==== normal send tokens to tax wallet ====
            
            super._transfer(from, to, transferAmount);
            super._transfer(from, taxWallet, taxAmount);
            
            //==== tokens burned instead of sending to tax wallet ====
            /*
            if (to == uniswapContractAddress){
                super._transfer(from, to, transferAmount);
                _burn(from, taxAmount);    
            }
            else {
                super._transfer(from, to, transferAmount);
                _burn(msg.sender, taxAmount);
            }
            */
        } 
        
        else {
            super._transfer(from,to,amount);
        }
        
        
    }


    // ==== Checks before token transfer happens ====
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual  {      
        // ==== Check if wallet is blacklisted ====
        require(!blacklisted[to] && !blacklisted[from], "Wallet is blacklisted");

        // ==== Check if trading started ====
        if (uniswapContractAddress == address(0) && from != address(0)) {
            require(from == owner(), "Trading yet to begin");
            return;
        }

        // ==== Check if successful buy transaction will exceed holding limit ====
        if (holdLimitState && from == uniswapContractAddress && (block.timestamp - tradingStartTime <= holdLimitWindow)) {
            require(super.balanceOf(to) + amount <= holdLimitAmount, "Exceeds allowable holding limit per wallet");
        }

    }
}