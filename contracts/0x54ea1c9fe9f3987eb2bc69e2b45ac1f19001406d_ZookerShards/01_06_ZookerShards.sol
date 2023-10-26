// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ZookerShards is ERC20, ERC20Burnable {
    constructor() ERC20("Zooker Shards", "ZKRS") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}