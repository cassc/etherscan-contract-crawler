// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OppsCoin is ERC20, Ownable {
    constructor() ERC20("OppsCoin", "OPPS") {
        _mint(msg.sender, 800854206900 * 10 ** decimals());
    }
}