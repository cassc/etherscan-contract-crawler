// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20, ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

// solhint-disable-next-line no-empty-blocks
contract OXE is ERC20Permit {
    constructor(address owner)
        ERC20("Omnia Exchange Token", "OXE")
        ERC20Permit("Omnia DeFi")
    {
        _mint(owner, 10 * 10**6 * 1 ether);
    }
}