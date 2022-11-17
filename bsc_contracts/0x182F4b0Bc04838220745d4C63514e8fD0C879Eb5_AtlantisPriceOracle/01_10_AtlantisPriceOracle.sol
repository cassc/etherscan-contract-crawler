// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@binance-oracle/binance-oracle-starter/contracts/interfaces/FeedRegistryInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AtlantisPriceOracleProxy.sol";
import "./AtlantisPriceOracleStorage.sol";

interface IAToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function underlying() external view returns (address);
}

interface IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract AtlantisPriceOracle is AtlantisPriceOracleStorage {
    using SafeMath for uint256;

    event PricePosted(address asset, uint256 previousPriceMantissa, uint256 requestedPriceMantissa, uint256 newPriceMantissa);

    event FeedSet(address feed, string symbol);

    FeedRegistryInterface internal feedRegistry;

    constructor() {}

    function getUnderlyingPrice(address _aToken) external view returns (uint256 answer) {
        IAToken aToken = IAToken(_aToken);

        if (compareStrings(aToken.symbol(), "aBNB")) {
            return getLatestAnswer("BNB");
        } else {
            return getPrice(aToken);
        }
    }

    function getPrice(IAToken aToken) internal view returns (uint256 price) {
        if (prices[address(aToken)] != 0) {
            price = prices[address(aToken)];
        } else {
            price = getLatestAnswer(IERC20(aToken.underlying()).symbol());
        }

        uint256 decimalDelta = uint256(18).sub(uint256(IERC20(aToken.underlying()).decimals()));
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return price.mul(10**decimalDelta);
        } else {
            return price;
        }
    }

    function getLatestAnswer(string memory symbol) public view returns (uint256 answer) {
        AggregatorV2V3Interface feedAdapter = getFeed(symbol);
        require(address(feedAdapter) != address(0), "Feed not found");

        // Oracle USD-denominated feeds store answers at 8 decimals
        uint decimalDelta = uint(18).sub(feedAdapter.decimals());

        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return uint256(feedAdapter.latestAnswer()).mul(10**decimalDelta);
        } else {
            return uint256(feedAdapter.latestAnswer());
        }
    }

    function decimals(address base, address quote) external view returns (uint8) {
        return feedRegistry.decimals(base, quote);
    }

    function getFeed(string memory symbol) public view returns (AggregatorV2V3Interface) {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }

    /*** Admin Functions ***/

    function setFeed(string calldata symbol, address feed) external onlyAdmin {
        require(feed != address(0) && feed != address(this), "invalid feed address");

        feeds[keccak256(abi.encodePacked(symbol))] = AggregatorV2V3Interface(feed);
        emit FeedSet(feed, symbol);
    }

    // This method is currently not used
    function setDirectPrice(address asset, uint256 price) external onlyAdmin {
        prices[asset] = price;
        emit PricePosted(asset, prices[asset], price, price);
    }

    function _become(AtlantisPriceOracleProxy atlantisPriceOracleProxy) external {
        require(msg.sender == atlantisPriceOracleProxy.admin(), "only proxy admin can change brains");
        atlantisPriceOracleProxy._acceptImplementation();
    }
}