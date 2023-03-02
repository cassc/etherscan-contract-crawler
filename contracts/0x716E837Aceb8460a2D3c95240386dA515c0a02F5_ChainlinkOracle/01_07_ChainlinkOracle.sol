// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Denominations.sol";
import "FeedRegistryInterface.sol";

import "IOracle.sol";

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    /// @notice `getRoundData` and `latestRoundData` should both raise "No data present"
    /// if they do not have data to report, instead of returning unset values
    /// which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ChainlinkOracle is IOracle {
    FeedRegistryInterface internal constant _feedRegistry =
        FeedRegistryInterface(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

    function isTokenSupported(address token) external view override returns (bool) {
        if (token == address(0)) return true;
        try _feedRegistry.getFeed(token, Denominations.ETH) returns (AggregatorV2V3Interface) {
            return true;
        } catch Error(string memory) {
            try _feedRegistry.getFeed(token, Denominations.USD) returns (AggregatorV2V3Interface) {
                return true;
            } catch Error(string memory) {
                return false;
            }
        }
    }

    // Prices are always provided with 18 decimals pecision
    function getUSDPrice(address token) external view returns (uint256) {
        return _getPrice(token, Denominations.USD, false);
    }

    function _getPrice(
        address token,
        address denomination,
        bool shouldRevert
    ) internal view returns (uint256) {
        if (token == address(0)) token = Denominations.ETH;
        try _feedRegistry.latestRoundData(token, denomination) returns (
            uint80 roundID_,
            int256 price_,
            uint256,
            uint256 timeStamp_,
            uint80 answeredInRound_
        ) {
            require(timeStamp_ != 0, "round not complete");
            require(price_ != 0, "negative price");
            require(answeredInRound_ >= roundID_, "stale price");
            return _scaleFrom(uint256(price_), _feedRegistry.decimals(token, denomination));
        } catch Error(string memory reason) {
            if (shouldRevert) revert(reason);

            if (denomination == Denominations.USD) {
                return
                    (_getPrice(token, Denominations.ETH, true) *
                        _getPrice(Denominations.ETH, Denominations.USD, true)) / 1e18;
            }
            return
                (_getPrice(token, Denominations.USD, true) * 1e18) /
                _getPrice(Denominations.ETH, Denominations.USD, true);
        }
    }

    function _scaleFrom(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) return value;
        if (decimals > 18) return value / 10**(decimals - 18);
        else return value * 10**(18 - decimals);
    }
}