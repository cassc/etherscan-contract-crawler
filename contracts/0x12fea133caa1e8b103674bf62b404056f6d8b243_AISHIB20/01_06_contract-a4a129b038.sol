// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract AISHIB20 is ERC20, Ownable {
    constructor() ERC20("AISHIB2.0", "AISHIB2.0") {
        _mint(msg.sender, 210000000000000000 * 10 ** decimals());
    }
}