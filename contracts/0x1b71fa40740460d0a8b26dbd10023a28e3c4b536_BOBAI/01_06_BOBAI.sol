// https://twitter.com/woof_decentra

//   ____   ____  ____          _____ 
//  |  _ \ / __ \|  _ \   /\   |_   _|
//  | |_) | |  | | |_) | /  \    | |  
//  |  _ <| |  | |  _ < / /\ \   | |  
//  | |_) | |__| | |_) / ____ \ _| |_ 
//  |____/ \____/|____/_/    \_\_____|                                                        

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract BOBAI is ERC20, Ownable {
    constructor() ERC20("BOBAI", "BOBAI") {
        _mint(msg.sender, 100_000_000_000 * (10 ** decimals()));
        renounceOwnership();
    }
}

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";