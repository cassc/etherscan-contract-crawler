//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ISudoPair {
    enum CurveErrorCodes {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }

    function withdrawAllETH() external;

    function withdrawETH(uint256 _amount) external;

    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable;

    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external;

    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        );

    function transferOwnership(address newOwner) external;

    function changeSpotPrice(uint128 newSpotPrice) external;
}