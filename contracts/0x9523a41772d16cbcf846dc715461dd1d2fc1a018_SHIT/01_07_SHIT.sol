// SHIT! A Whimsical World Where Shiba Speaks Tom!
// https://shitcoin.cyou	https://t.me/SHITOfficialPortal
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract SHIT is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SHIT", "SHIT") {
        _mint(msg.sender,  100000000 * (10 ** decimals())); 
    }

}