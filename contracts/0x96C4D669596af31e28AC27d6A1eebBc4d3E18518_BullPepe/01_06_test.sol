// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BullPepe is ERC20, Ownable {
    constructor() ERC20("Bull Pepe", "PAYPAY") {
        _mint(
            0x8a473F612F3b4084D99888A5204004BB9AbC4174,
            42069000000000000000000000000000
        );
    }
}