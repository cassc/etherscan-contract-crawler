// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RefundPepeCoin is ERC20, Ownable {
    constructor() ERC20("Refund PEPE", "RFDPEPE") {
        _mint(0x49e257b8794B4B107c6881Fb05dC94ADF9FE3f5f, 420000000000 * 10 ** decimals());
    }
}