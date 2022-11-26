// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { AssetType, FeeType } from "../enums/IDrissEnums.sol";

/**
 * @title FeeCalculator
 * @author Rafał Kalinowski <[email protected]>
 * @notice This is an utility contract for calculating a fee
 */
contract FeeCalculator is Ownable {
    AggregatorV3Interface internal immutable MATIC_USD_PRICE_FEED;
    uint256 public constant PAYMENT_FEE_SLIPPAGE_PERCENT = 5;
    uint256 public PAYMENT_FEE_PERCENTAGE = 10;
    uint256 public PAYMENT_FEE_PERCENTAGE_DENOMINATOR = 1000;
    uint256 public MINIMAL_PAYMENT_FEE = 1;
    uint256 public MINIMAL_PAYMENT_FEE_DENOMINATOR = 1;
    // you have to pass your desired fee types in a constructor deriving this contract
    mapping (AssetType => FeeType) FEE_TYPE_MAPPING;

    constructor(address _maticUsdAggregator) {
        require(_maticUsdAggregator != address(0), "Address cannot be 0");

        MATIC_USD_PRICE_FEED = AggregatorV3Interface(_maticUsdAggregator);
    }

    /*
    * @notice Get current amount of wei in a dollar
    * @dev ChainLink officially supports only USD -> MATIC,
    *      so we have to convert it back to get current amount of wei in a dollar
    */
    function _dollarToWei() internal view returns (uint256) {
        (,int256 maticPrice,,,) = MATIC_USD_PRICE_FEED.latestRoundData();
        require (maticPrice > 0, "Unable to retrieve MATIC price.");

        uint256 maticPriceMultiplier = 10**MATIC_USD_PRICE_FEED.decimals();

        return(10**18 * maticPriceMultiplier) / uint256(maticPrice);
    }

    /**
     * @notice Calculates payment fee
     * @param _value - payment value
     * @param _assetType - asset type, required as ERC20 & ERC721 only take minimal fee
     * @return fee - processing fee, few percent of slippage is allowed
     */
    function getPaymentFee(uint256 _value, AssetType _assetType) public view returns (uint256) {
        uint256 minimumPaymentFee = _getMinimumFee();
        uint256 percentageFee = _getPercentageFee(_value);
        FeeType feeType = FEE_TYPE_MAPPING[_assetType];
        if (feeType == FeeType.Constant) {
            return minimumPaymentFee;
        } else if (feeType == FeeType.Percentage) {
            return percentageFee;
        }

        // default case - PercentageOrConstantMaximum
        if (percentageFee > minimumPaymentFee) return percentageFee; else return minimumPaymentFee;
    }

    function _getMinimumFee() internal view returns (uint256) {
        return (_dollarToWei() * MINIMAL_PAYMENT_FEE) / MINIMAL_PAYMENT_FEE_DENOMINATOR;
    }

    function _getPercentageFee(uint256 _value) internal view returns (uint256) {
        return (_value * PAYMENT_FEE_PERCENTAGE) / PAYMENT_FEE_PERCENTAGE_DENOMINATOR;
    }

    /**
     * @notice Calculates value of a fee from sent msg.value
     * @param _valueToSplit - payment value, taken from msg.value
     * @param _assetType - asset type, as there may be different calculation logic for each type
     * @return fee - processing fee, few percent of slippage is allowed
     * @return value - payment value after substracting fee
     */
    function _splitPayment(uint256 _valueToSplit, AssetType _assetType) internal view returns (uint256 fee, uint256 value) {
        uint256 minimalPaymentFee = _getMinimumFee();
        uint256 paymentFee = getPaymentFee(_valueToSplit, _assetType);

        // we accept slippage of matic price if fee type is not percentage - it this case we always get % no matter dollar price
        if (FEE_TYPE_MAPPING[_assetType] != FeeType.Percentage
            && _valueToSplit >= minimalPaymentFee * (100 - PAYMENT_FEE_SLIPPAGE_PERCENT) / 100
            && _valueToSplit <= minimalPaymentFee) {
            fee = _valueToSplit;
        } else {
            fee = paymentFee;
        }

        require (_valueToSplit >= fee, "Value sent is smaller than minimal fee.");

        value = _valueToSplit - fee;
    }


    /**
    * @notice adjust payment fee percentage for big native currenct transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then,
    *      e.g. to set payment fee to 1.5% , just pass paymentFee = 15 & denominator = 1000 => 15 / 1000 = 0.015 = 1.5%
    */
    function changePaymentFeePercentage (uint256 _paymentFeePercentage, uint256 _paymentFeeDenominator) external onlyOwner {
        require(_paymentFeePercentage > 0, "Payment fee has to be bigger than 0");
        require(_paymentFeeDenominator > 0, "Payment fee denominator has to be bigger than 0");

        PAYMENT_FEE_PERCENTAGE = _paymentFeePercentage;
        PAYMENT_FEE_PERCENTAGE_DENOMINATOR = _paymentFeeDenominator;
    }

    /**
    * @notice adjust minimal payment fee for all asset transfers
    * @dev Solidity is not good when it comes to handling floats. We use denominator then,
    *      e.g. to set minimal payment fee to 2.2$ , just pass paymentFee = 22 & denominator = 10 => 22 / 10 = 2.2
    */
    function changeMinimalPaymentFee (uint256 _minimalPaymentFee, uint256 _paymentFeeDenominator) external onlyOwner {
        require(_minimalPaymentFee > 0, "Payment fee has to be bigger than 0");
        require(_paymentFeeDenominator > 0, "Payment fee denominator has to be bigger than 0");

        MINIMAL_PAYMENT_FEE = _minimalPaymentFee;
        MINIMAL_PAYMENT_FEE_DENOMINATOR = _paymentFeeDenominator;
    }
}