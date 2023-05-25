// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cactuar is ERC20 {

    /*
      Cactuar (CACTI) 

      - 1,000,000,000,000 fixed total supply 
      - 0% tax, stealth launched, no owner functions 
      - 100% Liquidity locked
      - No dev tokens, no presale
      - No community, no wens 
      - Play the game at https://cactuar.fun 
    */

    constructor() ERC20("Cactuar", "CACTI") {
        uint256 supply = 1000000000000 * 10 ** 18; 
        _mint(msg.sender, supply);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

}