// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/*
    ____                   __        __                    __        
   / __ \__  ___________  / /__     / /   ____ _____ ___  / /_  ____ 
  / /_/ / / / / ___/ __ \/ / _ \   / /   / __ `/ __ `__ \/ __ \/ __ \
 / ____/ /_/ / /  / /_/ / /  __/  / /___/ /_/ / / / / / / /_/ / /_/ /
/_/    \__,_/_/  / .___/_/\___/  /_____/\__,_/_/ /_/ /_/_.___/\____/ 
                /_/                                                  
*/

contract PurpleLambo is ERC20 {
    constructor() ERC20("Purple Lambo", "PURPLE", 18) {
        uint256 amount = 100_000_000 ether;
        _mint(msg.sender, amount);
    }

    function image() public pure returns (string memory) {
        return "https://arweave.net/tovQ6c5iuKah_wfPwGQT8W1m272C0O10uiuB0KFKEJo";
    }
}