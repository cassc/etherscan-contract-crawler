// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SpongeBobToken is ERC20, Ownable {
    constructor() ERC20("SpongeBob", "SPONGE") {
        _mint(0x5195BBBAf2e296CCF41371d37d942412522159E6, 40400000000 * 10 ** decimals());
        transferOwnership(0x5195BBBAf2e296CCF41371d37d942412522159E6);
    }
}