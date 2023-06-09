// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*

 /$$      /$$ /$$     /$$ /$$   /$$ /$$$$$$$$ /$$$$$$$$
| $$$    /$$$|  $$   /$$/| $$$ | $$| $$_____/|__  $$__/
| $$$$  /$$$$ \  $$ /$$/ | $$$$| $$| $$         | $$   
| $$ $$/$$ $$  \  $$$$/  | $$ $$ $$| $$$$$      | $$   
| $$  $$$| $$   \  $$/   | $$  $$$$| $$__/      | $$   
| $$\  $ | $$    | $$    | $$\  $$$| $$         | $$   
| $$ \/  | $$    | $$    | $$ \  $$| $$         | $$   
|__/     |__/    |__/    |__/  \__/|__/         |__/  

*/
                                                       
                                                       
contract MYNFTToken is ERC20 {
    constructor() ERC20("LaunchMyNFT", "MYNFT") {
        _mint(0x79533b96Ad6693c5a65beB490B0d88137FE926f1, 1000000000 * (10 ** uint256(decimals())));
    }
}