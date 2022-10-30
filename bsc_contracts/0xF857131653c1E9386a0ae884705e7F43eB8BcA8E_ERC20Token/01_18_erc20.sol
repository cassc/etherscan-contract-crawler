// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20Token is ERC20PresetMinterPauser, Ownable {
    constructor() ERC20PresetMinterPauser("Name", "N") {}
}