// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../lib/Assets.sol";
import "../AssetHandler.sol";
import "../RecoverableFunds.sol";
import "./InvestNFT.sol";
import "./InvestNFTMarketPricePolicy.sol";

contract InvestNFTMarket is AccessControl, Pausable, AssetHandler, RecoverableFunds {

    InvestNFT public investNFT;
    InvestNFTMarketPricePolicy public pricePolicy;
    uint256 public sharesBought;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setInvestNFT(address newInvestNFT) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investNFT = InvestNFT(newInvestNFT);
    }

    function setPricePolicy(address newPricePolicy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pricePolicy = InvestNFTMarketPricePolicy(newPricePolicy);
    }

    function setAsset(Assets.Key key, string memory assetTicker, Assets.AssetType assetType) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return _setAsset(key, assetTicker, assetType);
    }

    function removeAsset(Assets.Key key) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return _removeAsset(key);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function getAvailableShares() public view returns (uint) {
        return investNFT.totalShares() - investNFT.issuedShares();
    }

    function getEstimationForSpecifiedShares(uint256 desiredShares, Assets.Key assetKey) public view returns (uint256 shares, uint256 sum) {
        uint256 availableShares = getAvailableShares();
        shares = (desiredShares > availableShares) ? availableShares : desiredShares;
        uint256 price = pricePolicy.getPrice(shares, assetKey);
        sum = price * shares;
    }

    function getEstimationForSpecifiedAmount(uint256 amount, Assets.Key assetKey) public view returns (uint256 shares, uint256 sum) {
        uint256 availableShares = getAvailableShares();
        uint256 desiredShares = pricePolicy.getTokensForSpecifiedAmount(amount, assetKey);
        shares = (desiredShares > availableShares) ? availableShares : desiredShares;
        uint256 price = pricePolicy.getPrice(shares, assetKey);
        sum = shares * price;
    }

    function buyExactShares(uint256 desiredShares, Assets.Key assetKey) external whenNotPaused {
        (uint256 shares, uint256 sum) = getEstimationForSpecifiedShares(desiredShares, assetKey);
        require(shares > 0, "InvestNFTMarket: no shares available for purchase");
        sharesBought += shares;
        _transferAssetFrom(msg.sender, address(this), sum, assetKey);
        investNFT.safeMint(msg.sender, shares);
    }

    function buyForSpecifiedAmount(uint256 amount, Assets.Key assetKey) external whenNotPaused {
        (uint256 shares, uint256 sum) = getEstimationForSpecifiedAmount(amount, assetKey);
        require(shares > 0, "InvestNFTMarket: no shares available for purchase");
        sharesBought += shares;
        _transferAssetFrom(msg.sender, address(this), sum, assetKey);
        investNFT.safeMint(msg.sender, shares);
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveTokens(recipient, tokenAddress);
    }

    function retrieveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveETH(recipient);
    }

}