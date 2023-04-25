// contracts/IYKYK.sol
// SPDX-License-Identifier: MIT

//  /$$$$$$$$ /$$$$     /$$$$ /$$$$   /$$$$ /$$$$     /$$$$ /$$$$   /$$$$
// |_  $$$$_/|  $$$$   /$$$$/| $$$$  /$$$$/|  $$$$   /$$$$/| $$$$  /$$$$/
//   | $$$$   \  $$$$ /$$$$/ | $$$$ /$$$$/  \  $$$$ /$$$$/ | $$$$ /$$$$/ 
//   | $$$$    \  $$$$$$/    | $$$$$$$/      \  $$$$$$/    | $$$$$$$/  
//   | $$$$     \  $$$$/     | $$$$  $$$$     \  $$$$/     | $$$$  $$$$  
//   | $$$$      | $$$$      | $$$$\  $$$$     | $$$$      | $$$$\  $$$$ 
//  /$$$$$$$$    | $$$$      | $$$$ \  $$$$    | $$$$      | $$$$ \  $$$$
//  |_______/    |____/      |____/  \____/    |____/      |____/  \____/
                                                    
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IYKYK is ERC20 {
    constructor(uint256 initialSupply) ERC20("IYKYK", "IYKYK") {
        _mint(msg.sender, initialSupply);
    }
}