// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract WeChat is ERC20, Ownable {
    constructor() ERC20("WeChat", "WeChat") {
        _mint(0x5ddc1ADCA3E482B4C25bfe4722A649FA9fDFaD23, 100000000 * 10 ** decimals());
        transferOwnership(0x5ddc1ADCA3E482B4C25bfe4722A649FA9fDFaD23);
    }
}