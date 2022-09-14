// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

import {ISudoGatePoolSource} from "ISudoGatePoolSource.sol";

interface ISudoGate01 is ISudoGatePoolSource { 
    // In addition to ISudoGatePoolSource's tracking of pools, the v1 API allows buying
    function buyQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyFromPool(address pool) external payable returns (uint256 tokenID);
}