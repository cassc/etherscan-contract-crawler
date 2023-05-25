// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

///	@title	Kromatika token contract
contract Kromatika is ERC20Permit {

    constructor() ERC20("Kromatika", "KROM") ERC20Permit("Kromatika") {
        _mint(msg.sender, 100_000_000e18);
    }
}