// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/utils/Admin.sol";

contract LegacyToken is ERC20, Admin {
    constructor() ERC20("LegacyToken", "LT") Admin(msg.sender) {
        _mint(msg.sender, 320000000 * 10 ** decimals());
    }
}