// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "borrow/oracle/BaseOracleChainlinkMulti.sol";
import "../../../interfaces/external/curve/ICurveCryptoSwapPool.sol";

/// @title Oracle3CRVEURChainlink
/// @author Angle Labs, Inc.
/// @notice Gives a lower bound of the price of Curve 3CRV in Euro in base 18
contract Oracle3CRVEURChainlink is BaseOracleChainlinkMulti {
    string public constant DESCRIPTION = "3Crv/EUR Oracle";
    ICurveCryptoSwapPool public constant USDBP = ICurveCryptoSwapPool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    constructor(uint32 _stalePeriod, address _treasury) BaseOracleChainlinkMulti(_stalePeriod, _treasury) {}

    function circuitChainlink() public pure override returns (AggregatorV3Interface[] memory) {
        AggregatorV3Interface[] memory _circuitChainlink = new AggregatorV3Interface[](4);
        // Chainlink DAI/USD address
        _circuitChainlink[0] = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        // Chainlink USDC/USD address
        _circuitChainlink[1] = AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
        // Chainlink USDT/USD address
        _circuitChainlink[2] = AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
        // Chainlink EUR/USD address
        _circuitChainlink[3] = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        return _circuitChainlink;
    }

    /// @inheritdoc IOracle
    function read() external view override returns (uint256 quoteAmount) {
        AggregatorV3Interface[] memory _circuitChainlink = circuitChainlink();
        // We use 0 decimals when reading fees through `readChainlinkFeed` since all feeds have 8 decimals
        // and the virtual price of the Curve pool is given in 18 decimals, just like the amount of decimals
        // of the 3CRV token
        uint256 daiPrice = _readChainlinkFeed(1, _circuitChainlink[0], 1, 0);
        uint256 usdcPrice = _readChainlinkFeed(1, _circuitChainlink[1], 1, 0);
        uint256 usdtPrice = _readChainlinkFeed(1, _circuitChainlink[2], 1, 0);
        // Picking the minimum price between DAI, USDC and USDT, multiplying it by the pool's virtual price
        usdcPrice = usdcPrice >= daiPrice ? (daiPrice >= usdtPrice ? usdtPrice : daiPrice) : usdcPrice >= usdtPrice
            ? usdtPrice
            : usdcPrice;
        quoteAmount = _readChainlinkFeed((USDBP.get_virtual_price() * usdcPrice), _circuitChainlink[3], 0, 0);
    }
}