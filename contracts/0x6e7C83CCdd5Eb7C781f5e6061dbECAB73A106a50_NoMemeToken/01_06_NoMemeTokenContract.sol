// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NoMemeToken is ERC20, Ownable {
    constructor() ERC20("NoMeme", "NOMEME") {
        _mint(0xB413364E076d752837d6Bb5a8C6449bF1b0A638C, 9824000000 * 10 ** decimals());
        transferOwnership(0xB413364E076d752837d6Bb5a8C6449bF1b0A638C);
    }
}