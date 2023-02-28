// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BitCoinDex is ERC20 {
    uint256 maxSupply = 21_000_000 ether;

    constructor() ERC20("BitCoin Dex", "BCD") {
        _mint(_msgSender(), maxSupply);
    }

}