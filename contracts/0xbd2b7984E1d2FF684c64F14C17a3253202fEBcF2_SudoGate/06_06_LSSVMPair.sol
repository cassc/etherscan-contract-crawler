// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC721} from "IERC721.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

interface LSSVMPair {

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function factory() external pure returns (ILSSVMPairFactoryLike);
    
    function nft() external pure returns (IERC721);
    
    function poolType() external pure returns (PoolType);
    
    function getBuyNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );

    function getSellNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        );

      /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable  returns (uint256 inputAmount);

}