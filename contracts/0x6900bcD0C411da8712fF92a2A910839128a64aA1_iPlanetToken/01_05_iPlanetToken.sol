// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract iPlanetToken is ERC20 {
    uint256 private immutable _cap;

    constructor() ERC20("iPlanet Token", "IPT") {
        _cap = 1_000_000_000 ether;
        _mint(msg.sender, _cap);
    }
}