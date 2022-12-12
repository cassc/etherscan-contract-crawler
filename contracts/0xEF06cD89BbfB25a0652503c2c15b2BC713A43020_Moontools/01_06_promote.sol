/**
Hi, if you are reading this, it is because you search for a good token to ape/snipe!!!

We can help you with our eth/bnb  tools ecosystem

join our tg !!!! 

Moontools is a web-based sniper and copy trading Dapp. You just need to hold some $MTT to use it.

You can already check the Dapp at : https://beta.moontools.org/ ( sniper,clone trade, new pair sniffing )
we are waiting you in our telegram group https://t.me/MoonToolsErc to build a huge community





*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Moontools is ERC20, ERC20Burnable {
    constructor() ERC20("Not a token: read ca comment", "Not a token: read ca comment") {
        _mint(msg.sender, 100_000_000_000 * 10**18 );
    }
}