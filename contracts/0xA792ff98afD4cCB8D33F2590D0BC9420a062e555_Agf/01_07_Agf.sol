// SPDX-License-Identifier: Unlicensed
pragma solidity^0.8.15;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

/** 
*   Token Name: Gold Utility Token
*   Symbol: AGF
*   Total Supply: 5,000,000,000
*   Decimal: 10^18
*/ 

contract Agf is ERC20, Ownable, ERC20Burnable{

    constructor() ERC20("Gold Utility Token", "AGF"){
        // Total Supply: 5,000,000,000
        // Decimal: 10^18
        _mint(msg.sender, 5 * (10**9) * 10**18);
    }
}