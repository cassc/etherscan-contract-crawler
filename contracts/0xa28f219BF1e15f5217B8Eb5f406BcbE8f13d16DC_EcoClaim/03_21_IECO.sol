// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Helper interface for the eco currency
 */
interface IECO is IERC20 {
    function getPastLinearInflation(uint256 blockNumber)
        external
        view
        returns (uint256);
}