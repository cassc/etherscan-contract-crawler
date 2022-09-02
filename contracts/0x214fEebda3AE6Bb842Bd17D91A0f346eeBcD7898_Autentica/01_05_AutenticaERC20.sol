// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Autentica is ERC20 {
    constructor() ERC20("Autentica", "AUT") {
        _mint(_msgSender(), 1_000_000_000 * 10**decimals());
    }
}