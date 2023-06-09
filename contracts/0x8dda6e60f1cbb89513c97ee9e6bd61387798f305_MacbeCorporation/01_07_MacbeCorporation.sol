// SPDX-License-Identifier: MIT


///// 🌎 Website :::: https://macbe.co.in/
//// 📱 Telegram :::: https://t.me/MacbeToken
//// 🌐 Twitter :::: https://twitter.com/MacbeOfficial



pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MacbeCorporation is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private pair;


  
    uint256 public maxWallet;
    uint256 public maxTransaction;

    constructor(address To_) ERC20("Macbe Corporation", "MACBE") {

        
    
        maxWallet = 30 * 10 ** 5 * 10 ** decimals();
        maxTransaction = 20 * 10 ** 5 * 10 ** decimals();
      

        _mint(To_, 1 * 10 ** 8 * 10 ** decimals());
    }

  

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");

        pair[toPair] = true;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
 

        if( from != owner() && to != owner() && pair[to]) {
                require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");
                super._transfer(from, to, amount);
       }

        else if( from != owner() && to != owner() && pair[from]) {
                uint256 balance = balanceOf(to);
                require(balance.add(amount) <= maxWallet, "Transfer amount exceeds maximum wallet");
                require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");

                super._transfer(from, to, amount);
        }
        else if (from != owner() && to != owner()) {
            require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");
                    require(
                        
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
        }

       else {
           super._transfer(from, to, amount);
       }
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
    
        maxTransaction = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
       
        maxWallet = newNum * (10**18);
    }

}