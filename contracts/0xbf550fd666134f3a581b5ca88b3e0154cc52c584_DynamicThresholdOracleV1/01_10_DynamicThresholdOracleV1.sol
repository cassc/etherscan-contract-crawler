// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*
    MEGAMOON
    $MEGAM

    Website: https://megamooncoin.com/
    Twitter: https://twitter.com/MEGAMOON_eth
    Telegram: https://t.me/MEGAMOON_eth
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IDynamicThresholdOracle.sol";
import "./interfaces/IMegaMoonToken.sol";

contract DynamicThresholdOracleV1 is IDynamicThresholdOracle, Ownable {
    using SafeMath for uint;

    AggregatorV3Interface internal dataFeed;
    IMegaMoonToken public token;

    address public immutable WETH;
    address public pair;
    uint public factor = 1000;
    uint public fallbackValue = 1_000_000 * 1e18;
    bool public fallbackEnabled = false;

    constructor(
        address _dataFeed,
        address _token
    ) {
        dataFeed = AggregatorV3Interface(_dataFeed);
        token = IMegaMoonToken(_token);
        pair = token.pair();

        IUniswapV2Router02 router = IUniswapV2Router02(token.router());
        WETH = router.WETH();
    }

    function getBuyThreshold() external view returns (uint) {
        if (fallbackEnabled) return fallbackValue;
        uint marketCap = getMarketCapInUsd();
        uint delimiter = marketCap / factor;
        return delimiter * 1e12 / getLpPriceInUsd();
    }

    function getEthPrice() public view returns (uint) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        return uint(answer);
    }

    function getLpPrice() public view returns (uint) {
        uint wethBalance = IERC20(WETH).balanceOf(pair);
        uint tokenBalance = IERC20(address(token)).balanceOf(pair);
        return wethBalance * 1e12 / tokenBalance;
    }

    function getLpPriceInUsd() public view returns (uint) {
        return getLpPrice() * getEthPrice() / 1e8;
    }

    function getCirculatingSupply() public view returns (uint) {
        return IERC20(address(token)).totalSupply() -
            IERC20(address(token)).balanceOf(address(0xdead));
    }

    function getMarketCap() public view returns (uint) {
        return getLpPrice() * getCirculatingSupply() / 1e12;
    }

    function getMarketCapInUsd() public view returns (uint) {
        return getMarketCap() * getEthPrice() / 1e8;
    }

    function upgradeOracle(address newOracle) external onlyOwner returns (bool) {
        token.updateOracle(newOracle);
        return true;
    }

    function setPair(address newPair) external onlyOwner {
        pair = newPair;
    }

    function setFactor(uint newFactor) external onlyOwner {
        factor = newFactor;
    }

    function setFallbackEnabled(bool enabled) external onlyOwner {
        fallbackEnabled = enabled;
    }

    function setFallbackValue(uint newValue) external onlyOwner {
        fallbackValue = newValue * 1e18;
    }
}