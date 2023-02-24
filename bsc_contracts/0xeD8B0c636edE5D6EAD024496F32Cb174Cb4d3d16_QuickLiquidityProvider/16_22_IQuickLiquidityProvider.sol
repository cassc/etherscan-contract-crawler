// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import { QuoteInfo } from "../DexBase.sol";

interface IQuickLiquidityProvider {
    event QuoteAccepted(address indexed user, string quoteId, QuoteInfo quoteInfo);
    
    event QuoteRemoved(address indexed user, string quoteId);
    
    event SettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    
    event SettlementDecline(address indexed user, string quoteId, address asset, uint256 amount);
    
    event FinalSettlementDone(address indexed user, string quoteId, address asset, uint256 amount);
    
    event BackSignerSet(address indexed newSigner);

    function swapRequest(bytes calldata message, bytes[] calldata signature) external payable;

    function settle(string calldata quoteId, QuoteInfo calldata quote) external payable;

    function batchSettle(string[] calldata idArray, QuoteInfo[] calldata quotes) external payable;

    function vaultQuery(address token) external view returns (uint256);
}