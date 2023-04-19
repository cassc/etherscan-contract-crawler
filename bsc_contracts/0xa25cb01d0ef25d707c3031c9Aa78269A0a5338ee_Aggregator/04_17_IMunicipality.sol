// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMunicipality {

    struct LastPurchaseData {
        uint256 lastPurchaseDate;
        uint256 expirationDate;
        uint256 dollarValue;
    }    
    struct BundleInfo {
        uint256 parcelsAmount;
        uint256 minersAmount;
        uint256 bundlePrice;
        uint256 discountPct;
    }

    struct SuperBundleInfo {
        uint256 parcelsAmount;
        uint256 minersAmount;
        uint256 upgradesAmount;
        uint256 vouchersAmount;
        uint256 discountPct;
    }
    
    struct MinerInf {
        uint256 totalHash;
        uint256 freeHash;
    }

    function lastPurchaseData(address) external view returns (LastPurchaseData memory);
    function attachMinerToParcel(address user, uint256 firstMinerId, uint256[] memory parcelIds) external;
    function isTokenLocked(address _tokenAddress, uint256 _tokenId) external view returns(bool);
    function userToPurchasedAmountMapping(address _tokenAddress) external view returns(uint256);
    function updateLastPurchaseDate(address _user, uint256 _timeStamp) external;
    function minerParcelMapping(uint256 _tokenId) external view returns(uint256);
    function newBundles(uint256) external view returns(BundleInfo memory bundle);
    function superBundlesInfos(uint256) external view returns(SuperBundleInfo memory);
    function getPriceForBundle(uint8 _bundleType) external view returns(uint256, uint256);
    function getPriceForSuperBundle(uint8 _bundleType, address _user) external view returns(uint256,uint256);
    function setMinerInf(address _user, uint256 _totalHash, uint256 _freeHash) external;
    function minerInf(address _user) external view returns(MinerInf memory);
    function addFreeHash(address _user, uint256 _freeHash) external;
}