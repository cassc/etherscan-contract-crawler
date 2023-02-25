// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IYDTData {
    function acceptedTokens(address token)
        external view
        returns (
            string memory symbol,
            uint128 decimals,
            address tokenAddress,
            bool accepted,
            bool isChainLinkFeed,
            address priceFeedAddress,
            uint128 priceFeedPrecision
        );
    function isAcceptedToken(address token) external returns (bool);
}