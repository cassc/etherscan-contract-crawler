// SPDX-License-Identifier: MIT
/////https://moonhippoeth.com/

import "./ERC20.sol";
import "./Ownable.sol";


pragma solidity ^0.8.19;

/////MoonHippo.sol

contract MoonHippo is Ownable, ERC20 {
    bool public limited;
    
    uint256 public maxWallet = 25 * 10 ** 9 * 10 ** decimals();

    uint256 public maxTransaction=25 * 10 ** 9 * 10 ** decimals();
    address public uniswapV2Pair;
   

    constructor(address _to) ERC20("MoonHippo", "MHIPPO") {
        _mint(_to, 500 * 10 ** 9 * 10 ** decimals());
    }


    function setLimit(bool _limited) external onlyOwner {
        limited = _limited;
    }
        function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
    
        maxTransaction = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
       
        maxWallet = newNum * (10**18);
    }
    
      function addPair(address _uniswapV2Pair) public onlyOwner {
    uniswapV2Pair=_uniswapV2Pair;

        

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
      
       

     if (limited && to == uniswapV2Pair && to != owner() && from != owner()) {
            require( amount<= maxTransaction, "pool :transfer amount exceeds the maxTransactionAmount.");
        }

        if (limited && from == uniswapV2Pair && to != owner() && from != owner()) {
            require(super.balanceOf(to) + amount <= maxWallet && amount<= maxTransaction, "pool:exceeded max tx and wallet");
        }
        
        if (limited && to != owner() && from != owner()) {
            require(super.balanceOf(to) + amount <= maxWallet , "Max wallet exceeded");
        }

        if (limited && to != owner() && from != owner()) {
            require( amount <= maxTransaction , "transfer amount exceeds the maxTransactionAmount.");
        }
      
    }

  
}