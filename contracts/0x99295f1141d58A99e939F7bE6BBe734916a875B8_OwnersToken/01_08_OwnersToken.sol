// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./ERC677.sol";

/**
 * @title OwnersToken
 * @dev Pool Owners Token
 */
contract OwnersToken is ERC677 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 totalSupply
    ) ERC677(_name, _symbol) {
        _mint(msg.sender, totalSupply * (10**uint256(decimals())));
    }
}