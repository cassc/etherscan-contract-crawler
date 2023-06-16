/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⡆⠀⠀
⠀⠀⠀⠀⠀⠤⢤⣤⣀⣀⣀⡀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣀⠀⢠⣼⣿⣿⣿⡆⠀
⠀⠀⣠⣶⣶⣶⣤⣌⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠈⠉⠀⠛⠛⠃⠀
⠀⢰⣿⣿⣿⣿⣿⣿⣷⣄⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⡿⠛⠻⣿⣿⣿⣆⢹⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⣇⠀⠀⠘⣿⣿⣿⠀⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢿⣿⣿⣦⣤⣴⣿⣿⣿⠀⢸⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⠀⣾⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠙⠿⣿⣿⣿⡿⠋⠰⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract K0JI6ACA is Ownable, ERC20 {
    uint256 private _totalSupply = 69000000 * (10 ** 18);

    constructor() ERC20("K0JI6ACA", "K0JI6ACA", 18) {
        _mint(msg.sender, _totalSupply);
    }
}