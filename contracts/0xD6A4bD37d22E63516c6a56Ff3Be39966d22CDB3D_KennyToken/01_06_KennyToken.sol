// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract KennyToken is ERC20, Ownable {

    constructor() ERC20("KENNY", "KENNY") {
        _mint(0x168EB946d0403eaf3A99916Ce874DF2935bD6743, 420000000000000 * 10 ** decimals());
        transferOwnership(0x168EB946d0403eaf3A99916Ce874DF2935bD6743);
    }
}