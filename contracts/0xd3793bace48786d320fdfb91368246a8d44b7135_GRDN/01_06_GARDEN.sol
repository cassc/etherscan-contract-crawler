// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract GRDN is ERC20, Ownable {
    constructor() ERC20("GARDEN", "GRDN") {
        _mint(0x63a5AFb8f03c8b8F1f1c8635f1f6421de1D58cD7, 100000000 * 10 ** decimals());
        transferOwnership(0x63a5AFb8f03c8b8F1f1c8635f1f6421de1D58cD7);
    }
}