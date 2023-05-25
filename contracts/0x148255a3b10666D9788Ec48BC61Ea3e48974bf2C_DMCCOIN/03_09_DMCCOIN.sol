// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC777.sol";

contract DMCCOIN is ERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        ERC777("DMCCOIN", "DMCC", defaultOperators)
    {
        _mint(msg.sender, initialSupply, "", "");
    }
}