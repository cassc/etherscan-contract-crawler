// SPDX-License-Identifier: MIT

/*
About the platform:
Dexomatic is a trading insights and automated trading platform designed for Dex users. 
In its current form, it supports the Uniswap Dex on the Ethereum mainchain.
Support for other DEX/Chains is on the roadmap.

Trading Insights: Information is relayed to its users through several different Telegram channels.
Trading Bot: Trades can be automatically made based on Dexomatic Calls or user defined parameters.

About the token:
Dexomatic is designed to work on a two-token system.

$DEXO is the first of those tokens and serves as the access token for the platform.

3 Tiers offering access to different features are available at the moment of launch.
Holding a certain amount of $DEXO in your wallet is needed to access each desired tier.

More information:
https://t.me/Dexomatic
https://twitter.com/dexomatics

*/


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dexomatic is ERC20 {
    constructor() ERC20("Dexomatic", "DEXO") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}