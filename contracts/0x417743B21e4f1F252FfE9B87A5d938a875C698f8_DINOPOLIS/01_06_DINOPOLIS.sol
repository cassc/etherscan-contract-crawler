// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract DINOPOLIS is ERC20, Ownable {
    constructor() ERC20("DINOPOLIS", "DINO") {
        _mint(0x9fE5CaE2cB22BA3e0b3d688eCAA177a0D05f9c45, 999999999 * 10 ** decimals());
        transferOwnership(0x9fE5CaE2cB22BA3e0b3d688eCAA177a0D05f9c45);
    }
}