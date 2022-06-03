//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./VotesToken.sol";

/**
 * @dev Initilizes Supply of votesToken
 */
contract VotesTokenWithSupply is VotesToken {
    /**
    * @dev Mints tokens to hodlers w/ allocations 
    * @dev Returns the difference between total supply and allocations to treasury
    * @param name Token Name
    * @param symbol Token Symbol
    * @param hodlers Array of token receivers
    * @param allocations Allocations for each receiver
    * @param totalSupply Token's total supply
    * @param treasury Address to send difference between total supply and allocations
    */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory hodlers,
        uint256[] memory allocations,
        uint256 totalSupply,
        address treasury
    ) VotesToken(name, symbol) {
        uint256 tokenSum;
        for (uint256 i = 0; i < hodlers.length; i++) {
            _mint(hodlers[i], allocations[i]);
            tokenSum += allocations[i];
        }

        if (totalSupply > tokenSum) {
            _mint(treasury, totalSupply - tokenSum);
        }
    }
}