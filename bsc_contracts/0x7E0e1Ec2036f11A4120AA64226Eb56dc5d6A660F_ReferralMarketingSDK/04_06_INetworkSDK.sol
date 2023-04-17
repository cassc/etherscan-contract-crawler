// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface INetworkSDK {
    function calcRefSplit(
        uint256 _numTokens,
        bytes32 _referrerCode,
        uint256 _receivedTotal
    ) external view returns (
        uint256 sellPrice,
        uint256 __pricePerToken,
        uint256 networkAmount,
        uint256 referrerAmount,
        address referrerAddress,
        uint256 sellerAmount
    );

    function getPricePerToken() external view returns (uint256);
}