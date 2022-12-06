// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "./../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkLib {
    struct ApiInfo {
        string apiUrl;
        string[2] chainlinkRequestPath; //0 index contains buy and 1 contains sell
    }

    struct ChainlinkApiInfo {
        address chainlinkToken;
        address chainlinkOracle;
        bytes32 jobId;
        uint256 singleRequestFee;
    }
}

library SwapLib {
    uint256 constant BUY_INDEX = 0; //index used to indicate a BUY trx
    uint256 constant SELL_INDEX = 1; //index used to indicate a SELL trx
    uint256 constant SUPPORTED_DECIMALS = 8; //chainlink request and support contract decimals

    struct DexSetting {
        string comdexName; //name of the dex-pool
        uint256 tradeFee; //percentage fee deducted on each swap in 10**8 decimals
        address dexAdmin; //address responsible for certain admin functions e.g. addLiquidity
        uint256 rateTimeOut; //if expires swap will be paused
        uint256 unitMultiplier; //to convert feed price units to commodity token units
        uint256 buySpotDifference; // % difference in buy spot price e.g 112 means 1.12%
        uint256 sellSpotDifference; // % difference in sell spot price e.g 104 means 1.04%
    }

    struct DexData {
        uint256 reserveCommodity; //total commodity reserves
        uint256 reserveStable; //total stable reserves
        uint256 totalFeeCommodity; // storage that the fee of token A can be stored
        uint256 totalFeeStable; // storage that the fee of token B can be stored
        address commodityToken;
        address stableToken;
    }
    struct FeedInfo {
        //chainlink data feed reference
        AggregatorV3Interface priceFeed;
        uint256 heartbeat;
    }

    function _normalizeAmount(
        uint256 _amountIn,
        address _from,
        address _to
    ) internal view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).decimals();
        uint256 toDecimals = IERC20(_to).decimals();
        if (fromDecimals == toDecimals) return _amountIn;
        return
            fromDecimals > toDecimals
                ? _amountIn / (10**(fromDecimals - toDecimals))
                : _amountIn * (10**(toDecimals - fromDecimals));
    }

    function _checkFee(uint256 _fee) internal pure {
        require(_fee <= 10**8, "Lib: wrong fee amount");
    }

    function _checkRateTimeout(uint256 _newDuration) internal pure {
        require(
            _newDuration > 60 && _newDuration <= 300,//changed to minutes after delay implementation
            "Lib: invalid timeout"
        );
    }

    function _checkNullAddress(address _address) internal pure {
        require(_address != address(0), "Lib: invalid address");
    }
}

library PriceLib {
    struct PriceInfo {
        bytes32[] chainlinkRequestId; // = new bytes32[](2);//0 index contains buy and 1 contains sell
        uint256[] lastTimeStamp; // price time 0 index contains buy and 1 contains sell
        uint256[] lastPriceFeed; // price 0 index contains buy and 1 contains sell
        uint256[] lastRequestTime; // time of last request 0 index contains buy and 1 contains sell
        uint256[] cachedRequestTimeStamp; // request start time 0 index contains buy and 1 contains sell
    }
}