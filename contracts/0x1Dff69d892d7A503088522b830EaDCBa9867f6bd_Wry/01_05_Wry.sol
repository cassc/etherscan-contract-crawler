// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Wry: Wrapped Ycash
 */
contract Wry is ERC20 {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) public ERC20(name, symbol) {
        _mint(owner, initialSupply);
        _setupDecimals(8);
    }
}