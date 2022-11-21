// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IAnitoGacha {
    function gachaPrices(uint256 category) external view returns(uint256);
    function publicTotalMintedPerCategory(uint256 category) external view returns(uint256);
    function publicMaxMintPerCategory(uint256 category) external view returns(uint256);
}