// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EcoHunt is ERC20, Ownable {
    constructor(
        address founder
    ) payable ERC20("EcoHunt", "EHT") {
        _mint(founder, 1_000_000_000 * 10 ** 18);
        _transferOwnership(founder);
    }
}