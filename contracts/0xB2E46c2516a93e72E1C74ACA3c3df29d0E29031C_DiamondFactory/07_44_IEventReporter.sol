// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IClaim.sol";
import "./IAttribute.sol";

interface IEventReporter {
    function doBitgemMinted(address creator, string memory symbol, uint256 tokenId) external;
    function doClaimPriceChanged(string memory symbol, uint256 price) external;
    function doClaimRedeemed(address redeemer, Claim memory claim) external;
    function doClaimCreated(address minter, Claim memory claim) external;
    function doAttributeSet(address tokenAddress, uint256 tokenId, Attribute memory attribute) external;
    function doAttributeRemoved(address tokenAddress, uint256 tokenId, string memory key) external;
    function addAllowedReporter(address reporter) external; 
}