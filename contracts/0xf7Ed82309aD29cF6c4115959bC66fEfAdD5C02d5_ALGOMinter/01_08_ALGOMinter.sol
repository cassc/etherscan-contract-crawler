// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20Minter.sol";

contract ALGOMinter is ERC20Minter {
    constructor(address[] memory validators, uint16 threshold)
        ERC20Minter(validators, threshold, "Equito Wrapped ALGO", "WALGO")
    {}
}