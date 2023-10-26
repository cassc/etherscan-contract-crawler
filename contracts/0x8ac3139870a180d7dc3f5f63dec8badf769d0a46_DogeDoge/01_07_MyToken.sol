// SPDX-License-Identifier: MIT
// https://dogedoge.dog	https://t.me/DogeDogeOfficialPortal
pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract DogeDoge is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Doge Doge", "DODO") {
        _mint(msg.sender,  420690000000 * (10 ** decimals())); 
    }
}