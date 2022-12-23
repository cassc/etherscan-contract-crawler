// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20Minter.sol";

contract AlgoUsdcMinter is ERC20Minter {
    constructor(address[] memory validators, uint16 threshold)
        ERC20Minter(validators, threshold, "Equito Wrapped ALGO USDC", "AUSDC")
    {}
}