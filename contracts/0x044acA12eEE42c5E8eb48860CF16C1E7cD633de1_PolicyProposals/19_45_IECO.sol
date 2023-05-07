/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IECO is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function currentGeneration() external view returns (uint256);

    /**
     *  Returns final votes of an address at the end of a blocknumber
     */
    function getPastVotes(address owner, uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * Returns the final total supply at the end of the given block number
     */
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}