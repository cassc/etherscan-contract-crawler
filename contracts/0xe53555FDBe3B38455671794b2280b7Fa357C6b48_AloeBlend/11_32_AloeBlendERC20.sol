// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract AloeBlendERC20 is ERC20 {
    // solhint-disable no-empty-blocks
    constructor(string memory _name) ERC20(_name, "ALOE-BLEND", 18) {}
}