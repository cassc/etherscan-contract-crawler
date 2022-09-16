// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

import {ISudoGate01} from "ISudoGate01.sol";

interface ISudoGate02 is ISudoGate01 { 
    // v2 API extends v1 with selling
    function sellQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function sellQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    
    function sell(address nft, uint256 tokenId) external returns (bool success, uint256 priceInWei, uint256 feesInWei);
    function sellToPool(address nft, uint256 tokenId, address sudoswapPool, uint256 minPrice) external returns (uint256 priceInWei, uint256 feesInWei);
}