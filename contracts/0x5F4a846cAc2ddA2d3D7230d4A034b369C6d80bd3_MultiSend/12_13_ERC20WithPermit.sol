// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20WithPermit is ERC20Permit {
    constructor(string memory name) ERC20Permit(name) ERC20(name, "TTT") {
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }
}