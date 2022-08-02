// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./IFeedStrategy.sol";
import "./../../interfaces/IChainlinkPriceFeed.sol";

contract PriceFeedRouter is Ownable {
    using Address for address;

    mapping(string => uint256) public fiatNameToFiatId;
    mapping(uint256 => IFeedStrategy) public fiatIdToUsdStrategies;

    mapping(address => IFeedStrategy) public crytoToUsdStrategies;

    constructor(address gnosis, bool isTesting) {
        fiatNameToFiatId["USD"] = 1;
        if (!isTesting) {
            require(gnosis.isContract(), "PriceFeed: !contract");
            _transferOwnership(gnosis);
        }
    }

    function getPrice(address token, string calldata fiatName)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatNameToFiatId[fiatName]);
    }

    function getPrice(address token, uint256 fiatId)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatId);
    }

    function setCrytoStrategy(address strategy, address coin)
        external
        onlyOwner
    {
        crytoToUsdStrategies[coin] = IFeedStrategy(strategy);
    }

    function setFiatStrategy(
        string calldata fiatSymbol,
        uint256 fiatId,
        address fiatFeed
    ) external onlyOwner {
        require(fiatId != 1, "PriceFeed: id 1 reserved for USD");
        fiatNameToFiatId[fiatSymbol] = fiatId;
        fiatIdToUsdStrategies[fiatId] = IFeedStrategy(fiatFeed);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0");
        require(newOwner.isContract(), "PriceFeed: !contract");
        _transferOwnership(newOwner);
    }

    // 1.0 `token` costs `value` of [fiatId] (in decimals of `token`)
    function _getPrice(address token, uint256 fiatId)
        private
        view
        returns (uint256 value, uint8 decimals)
    {
        IFeedStrategy priceFeed = crytoToUsdStrategies[token];
        require(
            address(priceFeed) != address(0),
            "PriceFeedRouter: 1no priceFeed"
        );

        (int256 usdPrice, uint8 usdDecimals) = priceFeed.getPrice();
        require(usdPrice > 0, "PriceFeedRouter: 1feed lte 0");

        if (fiatId == 1) {
            return (uint256(usdPrice), usdDecimals);
        } else {
            IFeedStrategy fiatPriceFeed = fiatIdToUsdStrategies[fiatId];
            require(
                address(fiatPriceFeed) != address(0),
                "PriceFeedRouter: 2no priceFeed"
            );

            (int256 fiatPrice, uint8 fiatDecimals) = fiatPriceFeed.getPrice();
            require(fiatPrice > 0, "PriceFeedRouter: 2feed lte 0");

            return (
                (uint256(usdPrice) * 10**fiatDecimals) / uint256(fiatPrice),
                usdDecimals
            );
        }
    }
}