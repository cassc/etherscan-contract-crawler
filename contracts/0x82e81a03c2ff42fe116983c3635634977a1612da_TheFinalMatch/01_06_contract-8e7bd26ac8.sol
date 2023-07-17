// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract TheFinalMatch is ERC20, Ownable {
    constructor() ERC20("The Final Match", "MuskVsZuck ") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}