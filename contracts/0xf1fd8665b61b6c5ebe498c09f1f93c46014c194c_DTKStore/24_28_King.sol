// contracts/King.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract King is ERC20Burnable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;

    constructor() ERC20("KING", "KING") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}