// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeStop is ERC20, Ownable {
    mapping(address => bool) public blacklists;

    constructor() ERC20("PepeStop", "PSTP") {
        uint256 totalSupply = 420_690_000_000_000 ether;
        _mint(msg.sender, totalSupply);
    }
}