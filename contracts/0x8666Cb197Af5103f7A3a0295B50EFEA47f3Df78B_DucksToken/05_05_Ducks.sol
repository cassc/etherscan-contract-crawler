// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DucksToken is ERC20 {
    constructor(address holder) ERC20("Ducks", "DUCKS") {
        _mint(holder, 69_420_000_000_000 * 10**decimals());
    }
}