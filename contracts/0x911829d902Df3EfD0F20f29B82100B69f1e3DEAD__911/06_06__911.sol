// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./ERC20.sol";
import "./Ownable.sol";

/*
░█████╗░░░░░██╗░░███╗░░░░███╗░░
██╔══██╗░░░██╔╝░████║░░░████║░░
╚██████║░░██╔╝░██╔██║░░██╔██║░░
░╚═══██║░██╔╝░░╚═╝██║░░╚═╝██║░░
░█████╔╝██╔╝░░░███████╗███████╗
░╚════╝░╚═╝░░░░╚══════╝╚══════╝

https://www.911dead.com/
*/

contract _911 is ERC20, Ownable {
    constructor() ERC20("9/11", "9/11") {
        _mint(msg.sender, 2977000000 * 1000000000000000000);
    }
}