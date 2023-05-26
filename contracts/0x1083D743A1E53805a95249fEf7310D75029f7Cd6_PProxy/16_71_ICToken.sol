// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

interface ICToken {
    function mint(uint _mintAmount) external returns (uint256);
    function redeem(uint _redeemTokens) external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns(uint256);
}