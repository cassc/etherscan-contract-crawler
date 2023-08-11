// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";

contract PEPITO is ERC20, AccessControl {
    constructor() ERC20("PEPITO", "PEPITO") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}