// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract UbiloanToken is ERC20Votes, Ownable {

    uint256 private constant INITIAL_SUPPLY = 1_000_000_000;

    constructor() ERC20Permit("Ubiloan Token") ERC20("Ubiloan Token", "UNT") {
        _mint(msg.sender, INITIAL_SUPPLY * 10 ** 18);
    }

}