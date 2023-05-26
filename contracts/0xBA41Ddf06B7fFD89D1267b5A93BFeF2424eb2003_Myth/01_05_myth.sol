//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Myth is ERC20 {
    // Supply of 1 billion tokens.
    uint256 public constant INITIAL_SUPPLY = 1e9 ether;

    /**
     * Initializes the contract:
     *  - Mints 1 Billion tokens to `initialTokenHolder`
     */
    constructor(
        address initialTokenHolder
    ) ERC20("Mythos", "MYTH") {
        require(initialTokenHolder != address(0), "initialTokenHolder address cannot be 0");

        _mint(initialTokenHolder, INITIAL_SUPPLY);
    }
}