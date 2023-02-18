//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BearToken is ERC20, Ownable {
    constructor() ERC20("AlphaBear Token", "BEAR") {
        _mint(owner(), 1_000_000_000 * 10**decimals());
    }
}