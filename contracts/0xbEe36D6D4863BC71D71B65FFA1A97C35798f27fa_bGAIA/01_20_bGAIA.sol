// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./standards/ERC20G.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract bGAIA is ERC20Permit, ERC20G {
    constructor() ERC20Permit("Bonded GAIA") ERC20G("Bonded GAIA", "bGAIA") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20G) {
        super._beforeTokenTransfer(from, to, amount);
    }
}