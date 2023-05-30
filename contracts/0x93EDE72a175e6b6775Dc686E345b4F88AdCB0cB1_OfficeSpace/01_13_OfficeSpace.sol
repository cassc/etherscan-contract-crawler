// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract OfficeSpace is ERC20, ERC20Burnable, ERC20Permit {
    uint256 private constant Total_Supply = 100_000_000_000 ether;

    constructor() ERC20("Office Space", "OFSP") ERC20Permit("Office Space") {
        _mint(msg.sender, Total_Supply);
    }
}