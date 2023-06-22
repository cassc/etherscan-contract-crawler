// https://twitter.com/woof_decentra
//   _    _ _   _ _      ______           _____ _    _          _____ 
//  | |  | | \ | | |    |  ____|   /\    / ____| |  | |   /\   |_   _|
//  | |  | |  \| | |    | |__     /  \  | (___ | |__| |  /  \    | |  
//  | |  | | . ` | |    |  __|   / /\ \  \___ \|  __  | / /\ \   | |  
//  | |__| | |\  | |____| |____ / ____ \ ____) | |  | |/ ____ \ _| |_ 
//   \____/|_| \_|______|______/_/    \_\_____/|_|  |_/_/    \_\_____|                                                                   

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract UNLEASHAI is ERC20, Ownable {
    constructor() ERC20("UNLEASHAI", "UNLEASHAI") {
        _mint(msg.sender, 100_000_000_000 * (10 ** decimals()));
        renounceOwnership();
    }
}

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";