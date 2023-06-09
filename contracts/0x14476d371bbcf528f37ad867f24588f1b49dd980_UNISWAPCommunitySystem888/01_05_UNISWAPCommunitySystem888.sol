// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UNISWAPCommunitySystem888 is ERC20 {
    constructor() ERC20(unicode"UNISWAP中国CommunitySystem888", "UNISWAP") {
        _mint(msg.sender, 888000000 * 10 ** decimals());
    }
}