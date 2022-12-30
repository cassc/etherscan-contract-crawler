// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IArcadeGiveawayTokenHandler {
    /**
    * @notice function called from ArcadeGiveaway which is used to send tokens to users
    * @param to address of user where to send token
    * @param tokenId id of the token (not important for erc20)
    * @param amountTimes number of tokens to send
    */
    function handleGiveaway(address to, uint256 tokenId, uint256 amountTimes) external;
}