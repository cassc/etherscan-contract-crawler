// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KarenGPT is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("KarenGPT", "KGPT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}