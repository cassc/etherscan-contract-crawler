// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract CAKE is ERC20, Ownable {
    constructor() ERC20("CAKE", "CAKE") {
        _mint(0x4B24DdE8fc94F0c90E8bc5a940DCd2F9F7000000, 1234567890 * 10 ** decimals());
        transferOwnership(0x4B24DdE8fc94F0c90E8bc5a940DCd2F9F7000000);
    }
}