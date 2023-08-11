// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { ERC20Permit } from "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestTokenPermit is ERC20Permit {
    /* solhint-disable no-empty-blocks */
    constructor(string memory name, string memory symbol) public ERC20Permit(name) ERC20(name, symbol) {}
}