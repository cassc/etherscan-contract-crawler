// SPDX-License-Identifier: GPL-3.0
import "./Interfaces/IWhiteOptionsPricer.sol";

pragma solidity 0.6.12;

/**
 * @author jmonteer & 0mllwntrmt3
 * @title Whiteheart Options Pricer: Separate module to price protection of WHAssets
 * @notice Support contract that provides prices for certain protection periods, strikes and amounts
 */
contract WhiteOptionsPricer is IWhiteOptionsPricer, Ownable {
    using SafeMath for uint;

    uint256 public impliedVolRate;
    uint256 internal constant PRICE_DECIMALS = 1e8;

    AggregatorV3Interface public underlyingPriceProvider;

    constructor(AggregatorV3Interface _priceProvider) public {
        underlyingPriceProvider = _priceProvider;
        impliedVolRate = 5500;
    }

    /**
     * @notice Used for adjusting the options prices while balancing asset's implied volatility rate
     * @param value New IVRate value
     */
    function setImpliedVolRate(uint256 value) external onlyOwner {
        require(value >= 1000, "ImpliedVolRate limit is too small");
        impliedVolRate = value;
    }

    /**
     * @notice Returns the price that opening a certain option should cost
     * @param period period of protection
     * @param amount amount of underlying asset to be protected
     * @return total totalfee
     */
    function getOptionPrice(
        uint256 period,
        uint256 amount,
        uint256
    )
        external
        override
        view
        returns (uint256 total)
    {
        require(period <= 4 weeks, "!period: too long");
        require(period >= 1 days, "!period: too short");

        return amount
            .mul(sqrt(period))
            .mul(impliedVolRate)
            .div(PRICE_DECIMALS);
    }


    /**
     * @notice Returns the amount of WHAsset that is going to be created when provided with the total
     * amount of underlying asset sent (some goes to protecting the asset, some to the principal being protected)
     * @param total principal + hedgecost
     * @param period period of protection
     * @return maximum amount to be wrapped
     */
    function getAmountToWrapFromTotal(uint total, uint period) external view override returns (uint){
        uint numerator = total.mul(PRICE_DECIMALS).mul(10000);
        uint denominator = PRICE_DECIMALS.add(sqrt(period).mul(impliedVolRate));
        return numerator.div(denominator).div(10000);
    }

    /**
     * @dev Counts square root of the number.
     * Throws "invalid opcode" at uint(-1)

     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        result = x;
        uint256 k = (x + 1) >> 1;
        while (k < result) (result, k) = (k, (x / k + k) >> 1);
    }
}