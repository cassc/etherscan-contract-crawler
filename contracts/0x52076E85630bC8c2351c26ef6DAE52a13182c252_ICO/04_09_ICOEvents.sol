// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICOEvents {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 amountInUSD,
        uint256 totalTokens,
        uint32 IdCounter,
        uint32 vestingStartTime,
        bytes email,
        uint8 _type,
        address userAddress
    );
    event ClaimedToken(
        uint256 claimedAmount,
        uint256 IDCounter,
        address userAddress
    );

    event userKYC(bytes email);
}