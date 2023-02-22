//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlphaBearAI is ERC20, Ownable {
    constructor() ERC20("AlphaBEAR AI NFT", "NFT-AI") {
        _mint(owner(), 1_000_000_000 * 10**decimals());
    }
}