// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract xiasi is ERC20, Ownable {
    constructor() ERC20("XIASI", unicode"下司犬") {
        _mint(0x579dCE20a31d2c960F00e2617afc38df0db98D0C, 100000000 * 10 ** decimals());
        transferOwnership(0x579dCE20a31d2c960F00e2617afc38df0db98D0C);
    }
}