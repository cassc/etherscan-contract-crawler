// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { DSMath } from "../vendor/DSMath.sol";
import { IGnosisAuction } from "../interfaces/IGnosisAuction.sol";
import { IONtoken, IOracle } from "../interfaces/GammaInterface.sol";
import { IOptionsPremiumPricer } from "../interfaces/INeuron.sol";
import { Vault } from "./Vault.sol";
import { INeuronThetaVault } from "../interfaces/INeuronThetaVault.sol";

library GnosisAuction {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    struct AuctionDetails {
        address onTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 onTokenPremium;
        uint256 duration;
    }

    struct BidDetails {
        address onTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 auctionId;
        uint256 lockedBalance;
        uint256 optionAllocation;
        uint256 optionPremium;
        address bidder;
    }

    function startAuction(AuctionDetails calldata auctionDetails) internal returns (uint256 auctionID) {
        uint256 onTokenSellAmount = getONTokenSellAmount(auctionDetails.onTokenAddress);

        IERC20Detailed onToken = IERC20Detailed(auctionDetails.onTokenAddress);
        onToken.safeApprove(auctionDetails.gnosisEasyAuction, 0);
        onToken.safeApprove(auctionDetails.gnosisEasyAuction, onToken.balanceOf(address(this)));

        // minBidAmount is total onTokens to sell * premium per onToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount = DSMath.wmul(onTokenSellAmount.mul(10**10), auctionDetails.onTokenPremium);

        minBidAmount = auctionDetails.assetDecimals > 18
            ? minBidAmount.mul(10**(auctionDetails.assetDecimals.sub(18)))
            : minBidAmount.div(10**(uint256(18).sub(auctionDetails.assetDecimals)));

        require(minBidAmount <= type(uint96).max, "optionPremium * onTokenSellAmount > type(uint96) max value!");

        uint256 auctionEnd = block.timestamp.add(auctionDetails.duration);

        auctionID = IGnosisAuction(auctionDetails.gnosisEasyAuction).initiateAuction(
            // address of onToken we minted and are selling
            auctionDetails.onTokenAddress,
            // address of asset we want in exchange for onTokens. Should match vault `asset`
            auctionDetails.asset,
            // orders can be cancelled at any time during the auction
            auctionEnd,
            // order will last for `duration`
            auctionEnd,
            // we are selling all of the onTokens minus a fee taken by gnosis
            uint96(onTokenSellAmount),
            // the minimum we are willing to sell all the onTokens for. A discount is applied on black-scholes price
            uint96(minBidAmount),
            // the minimum bidding amount must be 1 * 10 ** -assetDecimals
            1,
            // the min funding threshold
            0,
            // no atomic closure
            false,
            // access manager contract
            address(0),
            // bytes for storing info like a whitelist for who can bid
            bytes("")
        );

        emit InitiateGnosisAuction(auctionDetails.onTokenAddress, auctionDetails.asset, auctionID, msg.sender);
    }

    function claimAuctionONtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) internal {
        bytes32 order = encodeOrder(auctionSellOrder.userId, auctionSellOrder.buyAmount, auctionSellOrder.sellAmount);
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        IGnosisAuction(gnosisEasyAuction).claimFromParticipantOrder(
            INeuronThetaVault(counterpartyThetaVault).optionAuctionID(),
            orders
        );
    }

    function getONTokenSellAmount(address onTokenAddress) internal view returns (uint256) {
        // We take our current onToken balance. That will be our sell amount
        // but onTokens will be transferred to gnosis.
        uint256 onTokenSellAmount = IERC20Detailed(onTokenAddress).balanceOf(address(this));

        require(onTokenSellAmount <= type(uint96).max, "onTokenSellAmount > type(uint96) max value!");

        return onTokenSellAmount;
    }

    function convertAmountOnLivePrice(
        uint256 _amount,
        address _assetA,
        address _assetB,
        address oracleAddress
    ) internal view returns (uint256) {
        if (_assetA == _assetB) {
            return _amount;
        }
        IOracle oracle = IOracle(oracleAddress);

        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        uint256 assetADecimals = IERC20Detailed(_assetA).decimals();
        uint256 assetBDecimals = IERC20Detailed(_assetB).decimals();

        uint256 decimalShift = assetADecimals > assetBDecimals
            ? 10**(assetADecimals.sub(assetBDecimals))
            : 10**(assetBDecimals.sub(assetADecimals));

        uint256 assetAValue = _amount.mul(priceA);

        return
            assetADecimals > assetBDecimals
                ? assetAValue.div(priceB).div(decimalShift)
                : assetAValue.mul(decimalShift).div(priceB);
    }

    function getONTokenPremium(
        address onTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IONtoken newONToken = IONtoken(onTokenAddress);
        IOptionsPremiumPricer premiumPricer = IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium = premiumPricer.getPremium(
            newONToken.strikePrice(),
            newONToken.expiryTimestamp(),
            newONToken.isPut()
        );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER);

        require(optionPremium <= type(uint96).max, "optionPremium > type(uint96) max value!");

        return optionPremium;
    }

    function getONTokenPremiumInToken(
        address oracleAddress,
        address onTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address convertFromToken,
        address convertTonToken
    ) internal view returns (uint256) {
        IONtoken newONToken = IONtoken(onTokenAddress);
        IOptionsPremiumPricer premiumPricer = IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium = premiumPricer.getPremium(
            newONToken.strikePrice(),
            newONToken.expiryTimestamp(),
            newONToken.isPut()
        );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER);

        optionPremium = convertAmountOnLivePrice(optionPremium, convertFromToken, convertTonToken, oracleAddress);

        require(optionPremium <= type(uint96).max, "optionPremium > type(uint96) max value!");

        return optionPremium;
    }

    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return bytes32((uint256(userId) << 192) + (uint256(buyAmount) << 96) + uint256(sellAmount));
    }
}