/**
Fluidity Exchange
Experience the fluidity of trading BTC, ETH, MATIC, XMR, AVAX, and over 175 diverse assets with unmatched security that prioritizes your privacy.

Why Choose Fluidity Exchange?

-NON-CUSTODIAL TRADING
-BYPASS TRADITIONAL KYC
-AUTOMATED AML PROTOCOLS
-HANDLING SUSPICIOUS ACTIVITIES

Fluidity Exchange is driven by seamless user experience, emphasizing fluidity in every transaction. 
We not only offer a wide range of cryptocurrencies but also prioritize user privacy and security, ensuring every trade is swift, secure, and private.

ABOUT FLUIDITY:      fluidity.exchange	
THE FLUIDITY PORTAL: t.me/FluidityExchange
FLUIDITY TWEETS:     twitter.com//Fluidi_Exchange
FLUIDITY DOC:        fluidity.exchange/wp-content/uploads/2023/08/Fluidity-Exchange-WhitePaper.pd
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FluidityExchange is ERC20 {
    constructor() ERC20("Fluidity Exchange", "FLUID") {
        _mint(msg.sender, 10_000_000_000 * 10**18);
    }
}