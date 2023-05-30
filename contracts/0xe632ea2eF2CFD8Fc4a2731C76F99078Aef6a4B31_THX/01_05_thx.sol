// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract THX is ERC20 {
    constructor(address[] memory to, uint256[] memory amount)
        ERC20("THX Network", "THX")
    {
        require(to.length == amount.length, "UNEQUAL_LENGTH");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]);
        }
    }
}