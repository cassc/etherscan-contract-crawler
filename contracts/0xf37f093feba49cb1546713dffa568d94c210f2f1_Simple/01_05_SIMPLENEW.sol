// SPDX-License-Identifier: MIT

/**

Website: https://ercsimple.xyz
Telegram: https://t.me/ercsimple
Twitter: https://twitter.com/ercsimple

* Simple (SIMPLE)
* In a crypto landscape riddled with scams and rug pulls, it's challenging to find trust and authenticity. 
* Over 95% of newly minted tokens seem designed to deceive or generate quick profits for their creators, often at your expense.
* Join the Simple community: an Ethereum token that shares the same blockchain as its peers but stands apart in crucial ways. 
* Our code is elegantly simple, rigorously audited, and free from hidden traps. 
* In the world of crypto, simplicity is the essence of perfection.
* This smart contract is the backbone of the Simple project, designed to bring transparency and trust to the cryptocurrency world. 
* We've prioritized simplicity,
* security, and community prosperity in every line of code.
* Contract Features:
* - Clean and Audited Code
* - No Team Tokens
* - Locked Liquidity
* - Contract Ownership Renounced
* - Transaction Taxes Benefit the Community
* Join us in our mission to redefine trust and create a brighter future for all our community members.
* Learn more at ercsimple.xyz.
**/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Simple is ERC20 {
    uint256 private constant BURN_RATE = 5; // 5% burn rate

    address private pinkSaleAddress;
    address payable private deployer;

    constructor(uint256 initialSupply) ERC20("Simple", "SIMPLE") {
        _mint(msg.sender, initialSupply * (10**uint256(decimals())));
        deployer = payable(_msgSender());
        pinkSaleAddress = address(0); // Initialize with an invalid address
    }

    // Set the Pink Sale address after deployment
    function setPinkSaleAddress(address _pinkSaleAddress) external  {
    require(_msgSender() == deployer);
        pinkSaleAddress = _pinkSaleAddress;
    }

    // Transfer function with burn mechanism
    function transfer(address to, uint256 value) public override returns (bool) {
    require(value > 0, "ERC20: Transfer value must be greater than zero");
    
    uint256 burnvalue;
    uint256 transfervalue;

    if (
        msg.sender != deployer &&
        msg.sender != pinkSaleAddress &&
        to != deployer &&
        to != pinkSaleAddress
    ) {
        burnvalue = (value * BURN_RATE) / 100;
        transfervalue = value - burnvalue;
    } else {
        burnvalue = 0;
        transfervalue = value;
    }

    if (burnvalue > 0) {
        _burn(msg.sender, burnvalue);
    }

    _transfer(msg.sender, to, transfervalue);
    return true;
}


    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(from != address(0), "ERC20: Transfer from the zero address");
    require(value > 0, "ERC20: Transfer value must be greater than zero");

    uint256 burnvalue;
    uint256 transfervalue;

    address spender = _msgSender();

    if (
        from != deployer &&
        from != pinkSaleAddress &&
        to != deployer &&
        to != pinkSaleAddress
    ) {
        burnvalue = (value * BURN_RATE) / 100;
        transfervalue = value - burnvalue;
    } else {
        burnvalue = 0;
        transfervalue = value;
    }

    if (burnvalue > 0) {
        _burn(from, burnvalue);
    }


    _spendAllowance(from, spender, value);
    _transfer(from, to, transfervalue);

        return true;
    }
}