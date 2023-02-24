// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "borrow/oracle/BaseOracleChainlinkMulti.sol";
import "../../../interfaces/external/curve/ITricryptoPool.sol";
import "../../../interfaces/external/curve/ICurveCryptoSwapPool.sol";

/// @title OracleLUSD3CRVEURChainlink
/// @author Angle Labs, Inc.
/// @notice Gives the price of Curve LUSD-3CRV in Euro in base 18
contract OracleLUSD3CRVEURChainlink is BaseOracleChainlinkMulti {
    string public constant DESCRIPTION = "LUSD3CRV/EUR Oracle";
    ITricryptoPool public constant LUSD_3CRV_POOL = ITricryptoPool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    ICurveCryptoSwapPool public constant USDBP = ICurveCryptoSwapPool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    constructor(uint32 _stalePeriod, address _treasury) BaseOracleChainlinkMulti(_stalePeriod, _treasury) {}

    function circuitChainlink() public pure override returns (AggregatorV3Interface[] memory) {
        AggregatorV3Interface[] memory _circuitChainlink = new AggregatorV3Interface[](5);
        // Chainlink DAI/USD address
        _circuitChainlink[0] = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        // Chainlink USDC/USD address
        _circuitChainlink[1] = AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
        // Chainlink USDT/USD address
        _circuitChainlink[2] = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        // Chainlink LUSD/USD address
        _circuitChainlink[3] = AggregatorV3Interface(0x3D7aE7E594f2f2091Ad8798313450130d0Aba3a0);
        // Chainlink EUR/USD address
        _circuitChainlink[4] = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        return _circuitChainlink;
    }

    /// @inheritdoc IOracle
    function read() external view override returns (uint256 quoteAmount) {
        quoteAmount = _readChainlinkFeed(_lpPrice(), circuitChainlink()[4], 0, 0);
    }

    /// @notice Gets the global LP token price
    function _lpPrice() internal view returns (uint256 lpMetaPrice) {
        uint256 lp3CRVPrice = _lpPriceBase();
        lpMetaPrice = _lpPriceMeta(lp3CRVPrice);
    }

    /// @notice Gets the meta LP token price
    function _lpPriceMeta(uint256 lower3CRVPrice) internal view returns (uint256 quoteAmount) {
        AggregatorV3Interface[] memory _circuitChainlink = circuitChainlink();
        // We use 0 decimals when reading fees through `readChainlinkFeed` since all feeds have 8 decimals
        // and the virtual price of the Curve pool is given in 18 decimals, just like the amount of decimals
        // of the LUSD3CRV token
        uint256 lusdPrice = _readChainlinkFeed(1, _circuitChainlink[3], 1, 0);
        // Picking the minimum price between LUSD and 3CRV price, multiplying it by the pool's virtual price
        lusdPrice = lusdPrice >= lower3CRVPrice ? lower3CRVPrice : lusdPrice;
        quoteAmount = (LUSD_3CRV_POOL.get_virtual_price() * lusdPrice);
    }

    /// @notice Get the underlying LP token price
    function _lpPriceBase() internal view returns (uint256 quoteAmount) {
        AggregatorV3Interface[] memory _circuitChainlink = circuitChainlink();
        uint256 daiPrice = _readChainlinkFeed(1, _circuitChainlink[0], 1, 0);
        uint256 usdcPrice = _readChainlinkFeed(1, _circuitChainlink[1], 1, 0);
        uint256 usdtPrice = _readChainlinkFeed(1, _circuitChainlink[2], 1, 0);
        // Picking the minimum price between DAI, USDC and USDT, multiplying it by the pool's virtual price
        usdcPrice = usdcPrice >= daiPrice ? (daiPrice >= usdtPrice ? usdtPrice : daiPrice) : usdcPrice >= usdtPrice
            ? usdtPrice
            : usdcPrice;
        quoteAmount = (USDBP.get_virtual_price() * usdcPrice) / 10**18;
    }
}