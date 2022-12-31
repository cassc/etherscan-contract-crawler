// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTServiceTypes.sol";

/**
 * Interface of NFTServiceProvider  
 */

interface INFTServiceProvider {
   function consumeCredits(Ticket memory ticket, uint256 creditsBefore)
        external returns (uint256 creditsConsumed);
}