// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

/**
 * @title Virus World Utils ERC20 Token
 * @author DEV VRWD Dan
 */
contract VirusERC20Token is ERC20PresetMinterPauser, Ownable {
    constructor(string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        mint(_msgSender(), 100_000_000 * 10 ** 18);
    }
}