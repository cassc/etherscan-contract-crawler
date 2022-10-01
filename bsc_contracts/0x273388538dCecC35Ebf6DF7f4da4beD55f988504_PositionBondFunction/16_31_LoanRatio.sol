/**
 * @author Musket
 */
pragma solidity ^0.8.9;

import "../../interfaces/IChainLinkPriceFeed.sol";

abstract contract LoanRatio {
    uint256 public liquidateRate;
    uint256 public maxLoanRatio;
    uint256 public twapInterval;

    bytes32 private priceFeedKeyUnderlyingAsset;
    bytes32 private priceFeedKeyFaceAsset;

    IChainLinkPriceFeed chainLinkPriceFeed;

    function initLoanLoanRatio(
        bytes32 priceFeedKeyUnderlyingAsset_,
        bytes32 priceFeedKeyFaceAsset_
    ) internal {
        priceFeedKeyUnderlyingAsset = priceFeedKeyUnderlyingAsset_;
        priceFeedKeyFaceAsset = priceFeedKeyFaceAsset_;
        liquidateRate = 8_000;
        maxLoanRatio = 6_500;
        twapInterval = 3 * 24 * 3600;
    }


    function initChainLinkPriceFeed(address chainLinkPriceFeed_) internal {
        chainLinkPriceFeed = IChainLinkPriceFeed(chainLinkPriceFeed_);
    }

    function _getLoanRatio(
        uint256 amountUnderlyingAsset,
        uint256 amountFaceAsset
    ) internal view returns (uint256) {
        if (amountUnderlyingAsset == 0 || amountFaceAsset == 0) {
            return 0;
        }
        return
            (chainLinkPriceFeed.getTwapPrice(
                priceFeedKeyFaceAsset,
                twapInterval
            ) *
                amountFaceAsset *
                10_000) /
            (chainLinkPriceFeed.getTwapPrice(
                priceFeedKeyUnderlyingAsset,
                twapInterval
            ) * amountUnderlyingAsset);
    }

    function isLiquidate(uint256 amountUnderlyingAsset, uint256 amountFaceAsset)
        internal
        view
        returns (bool)
    {
        return
            _getLoanRatio(amountUnderlyingAsset, amountFaceAsset) >=
            liquidateRate;
    }

    function isNotReachMaxLoanRatio(
        uint256 amountUnderlyingAsset,
        uint256 amountFaceAsset
    ) internal view returns (bool) {
        uint256 loanRatio = _getLoanRatio(
            amountUnderlyingAsset,
            amountFaceAsset
        );
        return loanRatio <= maxLoanRatio && loanRatio > 0;
    }
}