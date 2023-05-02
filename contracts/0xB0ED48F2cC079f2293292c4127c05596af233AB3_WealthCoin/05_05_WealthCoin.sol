// SPDX-License-Identifier: MIT  

pragma solidity ^0.8.18;

import "./ERC20Deflationary.sol";

contract WealthCoin is ERC20Deflationary {
    constructor() ERC20Deflationary("Wealth Coin","WEALTH"){
        _mint(msg.sender, 5555000000000 * 10 ** decimals());
    }
}