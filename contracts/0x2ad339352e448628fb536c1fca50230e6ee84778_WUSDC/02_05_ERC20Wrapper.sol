// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";


/** 
Extension of the ERC20 standard that replicates the functionality of the 
Wrapped Ether contract. It allows to wrap other tokens whose contracts are behind 
a proxy or that include censorship functions so that they can be used respecting 
the principles of transparency and decentralization of the blockchain. It also
removes any unexpected behavior from those tokens easing their use.
*/
contract ERC20Wrapper is ERC20 {

    IERC20Metadata public token;
    uint8 public tokenDecimals;

    constructor(string memory name, string memory symbol, address token_) ERC20(name, symbol) {
        token = IERC20Metadata(token_);
        tokenDecimals = token.decimals();
        require(tokenDecimals <= 18);
    }

    
    /// @dev Deposit amount of tokens in contract and mints amount of wrapped tokens
    /// @param amount using 18 decimals
    function deposit(uint256 amount) external {
        uint256 unWrappedAmount = amount / 10**(18-tokenDecimals);
        amount = unWrappedAmount * 10**(18-tokenDecimals); // Remove rounding errors
        token.transferFrom(msg.sender, address(this), unWrappedAmount);
        fulfillDeposit(amount);
    }

    /// @dev Withdraws amount of tokens to sender
    /// @param amount using 18 decimals
    function withdraw(uint256 amount) external {
        withdrawTo(msg.sender, amount);
    }
    
    /// @dev Low level method that allows direct transfer of tokens to this contract to skip the
    /// approve step. This function should only be called from another smart contract that performs 
    /// the token transfer before calling this function in an atomic transaction. Calling this 
    /// function manually after sending the tokens in a different transaction could result in the 
    /// loss of the funds if an attacker front-runs the call to this function.
    /// @param amount using 18 decimals
    function fulfillDeposit(uint256 amount) public {
        uint256 wrappedBalance = token.balanceOf(address(this)) * 10**(18-tokenDecimals);
        require(wrappedBalance >= totalSupply() + amount, "Insufficient deposit");
        _mint(msg.sender, amount);
    }
    
    /// @dev Withdraws amount of tokens to a different address
    /// @param amount using 18 decimals
    function withdrawTo(address to, uint256 amount) public {
        uint256 unWrappedAmount = amount / 10**(18-tokenDecimals);
        amount = unWrappedAmount * 10**(18-tokenDecimals); // Remove rounding errors
        
        _burnFrom(msg.sender, amount);
        token.transfer(to, unWrappedAmount);
        
        uint256 wrappedBalance = token.balanceOf(address(this)) * 10**(18-tokenDecimals);
        require(wrappedBalance >= totalSupply(), "Insufficient resulting balance");
    }
}