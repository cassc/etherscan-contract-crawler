// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Incentive Emissions Dummy", "INCENTIVE-MOCK") {
        _mint(0x91b3927f100Bb6c19E5434bFaBa07D60670b98D6, 1000 ether);
    }
}