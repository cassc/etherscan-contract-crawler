// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC20 } from "./token/ERC20/ERC20.sol";

import { ERC20Burnable } from "./token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "./token/ERC20/extensions/ERC20Permit.sol";

contract CryptoStrike is ERC20, ERC20Burnable, ERC20Permit {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

    mapping(address => uint256) private _balances;

    constructor(address owner) ERC20("Crypto Strike", "STRIKE", owner) ERC20Permit("Crypto Strike") {
        _mint(owner, MAX_SUPPLY);
        transferOwnership(owner);
    }
}