// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "./../interfaces/IERC20.sol";
library ChainlinkLib {
    struct ApiInfo {
        string _apiUrl;
        string[2] _chainlinkRequestPath; //0 index contains buy and 1 contains sell
    }
    struct ChainlinkInfo {
        address chainlinkToken;
        address chainlinkOracle;
        address chianlinkPriceFeed;
        bool chainlinkFeedEnabled;
    }
}

library SwapLib {
    uint256 constant BUY_INDEX = 0; //index used to indicate a BUY trx
    uint256 constant SELL_INDEX = 1; //index used to indicate a SELL trx
    struct DexSetting {
        string comdexName;//name of the dex-pool
        uint256 tradeFee;//percentage fee deducted on each swap in 10**8 decimals
        address dexAdmin;//address responsible for certain admin functions e.g. addLiquidity
        uint256 rateTimeOut;//if expires swap will be paused 
        uint256 unitMultiplier;//to convert feed price units to commodity token units
        address stableToUSDPriceFeed; //chainlink feed for stable/usd conversion
        uint256 buySpotDifference; // % difference in buy spot price e.g 112 means 1.12%
        uint256 sellSpotDifference; // % difference in sell spot price e.g 104 means 1.04%
    }

    struct DexData {
        uint256 reserveCommodity;
        uint256 reserveStable;
        uint256 totalFeeCommodity; // storage that the fee of token A can be stored
        uint256 totalFeeStable; // storage that the fee of token B can be stored
        address commodityToken;
        address stableToken;
    }

    function normalizeAmount(uint _amountIn, address _from, address _to) internal view returns(uint256){
        uint fromDecimals = IERC20(_from).decimals();
        uint toDecimals = IERC20(_to).decimals();
        if(fromDecimals == toDecimals) return _amountIn;
        return fromDecimals > toDecimals ? _amountIn / (10**(fromDecimals-toDecimals)) : _amountIn * (10**(toDecimals - fromDecimals));
    }

    function checkFee(uint _fee) internal pure{
        require(_fee <10**8, "wrong fee amount");
    }

    function checkcommodityTokenddress(address _commodityToken, address _stableToken) internal pure{
        require(_commodityToken != address(0) && _stableToken != address(0),"invalid token");
    }
}

library PriceLib {
    struct PriceInfo {
        uint256[] rates; //= new uint256[](2);//0 index contains buy and 1 contains sell
        bytes32[] chainlinkRequestId; // = new bytes32[](2);//0 index contains buy and 1 contains sell
        uint256[] lastTimeStamp; //= new uint256[](2);//0 index contains buy and 1 contains sell
        uint256[] lastPriceFeed; //= new uint256[](2);//0 index contains buy and 1 contains sell
    }
}