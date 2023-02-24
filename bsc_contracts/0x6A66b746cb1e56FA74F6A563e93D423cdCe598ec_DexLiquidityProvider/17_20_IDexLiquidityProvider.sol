// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { QuoteInfo } from "../DexBase.sol";

interface IDexLiquidityProvider {
    event QuoteAccepted(address indexed user, string quoteId, QuoteInfo quoteInfo);
    
    event QuoteRemoved(address indexed user, string quoteId);
    
    event SettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    
    event SettlementDecline(address indexed user, string quoteId, address asset, uint256 amount);
    
    event CompensateDone(string[] idArray);
    
    event BackSignerSet(address indexed newSigner);

    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable;

    function settle(string calldata quoteId, QuoteInfo calldata quote) external payable;

    function decline(string calldata quoteId, QuoteInfo calldata quote) external;

    function calculateCompensate(address user, string[] memory idArray, QuoteInfo[] memory quotes) external view returns (uint256); 

    function compensate(string[] memory idArray, QuoteInfo[] calldata quotes) external;
}