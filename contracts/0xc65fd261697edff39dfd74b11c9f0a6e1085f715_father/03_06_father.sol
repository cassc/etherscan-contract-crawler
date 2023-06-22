//    __      _   _               
//   / _|    | | | |              
//  | |_ __ _| |_| |__   ___ _ __ 
//  |  _/ _` | __| '_ \ / _ \ '__|
//  | || (_| | |_| | | |  __/ |   
//  |_| \__,_|\__|_| |_|\___|_|   
                               
                                                    
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract father is ERC20, Ownable {
    constructor() ERC20("father", "father") {
        _mint(msg.sender, 100_000_000_000 * (10 ** decimals()));
        renounceOwnership();
    }
}
