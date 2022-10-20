// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMunicipality {
    struct LastPurchaseData {
        uint256 lastPurchaseDate;
        uint256 expirationDate;
        uint256 dollarValue;
    }
    function lastPurchaseData(address) external view returns (LastPurchaseData memory);
    function attachMinerToParcel(address user, uint256 firstMinerId, uint256[] memory parcelIds) external;
    function isTokenLocked(address _tokenAddress, uint256 _tokenId) external view returns(bool);
}