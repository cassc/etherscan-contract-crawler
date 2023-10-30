// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Dune is ERC20 {
    constructor() ERC20("Dune", "DUNE") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}