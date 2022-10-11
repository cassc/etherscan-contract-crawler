// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IUsdcOracle.sol";

contract ChainlinkOracle is IUsdcOracle, AccessControl {
    /* ==========  Constants  ========== */

    // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/Denominations.sol
    address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;    
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant USD = address(840);

    uint256 public constant USDC_PRECISION = 1e6;
    uint256 public constant PRECISION = 1e18;
    
    FeedRegistryInterface immutable public registry;
    address public immutable USDC;
    address public immutable WETH;
    address public immutable WBTC;

    /* ==========  Constructor  ========== */

    constructor(address _chainlink_feedregistry, address _usdc, address _weth, address _wbtc) {
        require(_chainlink_feedregistry!= address(0), "ERR_FEEDREGISTRY_INIT");
        require(_usdc!= address(0), "ERR_USDC_INIT");
        require(_weth!= address(0), "ERR_WETH_INIT");
        require(_wbtc!= address(0), "ERR_WBTC_INIT");
        registry = FeedRegistryInterface(_chainlink_feedregistry);
        USDC = _usdc;
        WETH = _weth;
        WBTC = _wbtc;
    }

    /* ==========  External Functions  ========== */
    
    function tokenUsdcValue(address _token, uint256 _amount)
        external
        view
        override
        returns (uint256 usdcValue, uint256 oldestObservation)
    {
        if (_token == USDC) {
            return (_amount, block.timestamp);
        }
        uint8 decimals = IERC20Metadata(_token).decimals();
        uint256 price;
        (price, oldestObservation) = getPrice(_token, USDC);
        usdcValue = _amount * price * USDC_PRECISION / (10 ** decimals) / PRECISION;
        return (usdcValue, oldestObservation);
    }

    function getPrice(address _base, address _quote) public view override returns (uint256, uint256) {
        uint256 oldestObservation;
        uint256 price;
        if (_quote == WETH) {
              (price, oldestObservation) = getPrice(_base, ETH);
              return (price, oldestObservation);
        }
        if (_base == WETH) {
              (price, oldestObservation) = getPrice(ETH, _quote);
              return (price, oldestObservation);
        }
        if (_quote == WBTC) {
              (price, oldestObservation) = getPrice(_base, BTC);
              return (price, oldestObservation);
        }
        if (_base == WBTC && _quote != BTC) {
              (uint256 wbtc_btc_price, uint256 oldestObservation1) = getPrice(WBTC, BTC);
              (uint256 btc_quote_price, uint256 oldestObservation2) = getPrice(BTC, _quote);
              uint256 wbtc_price =  wbtc_btc_price * btc_quote_price / PRECISION;
              oldestObservation = (oldestObservation1 < oldestObservation2) ? oldestObservation1 : oldestObservation2;
              return (wbtc_price, oldestObservation);
        }
        if (_quote == USDC) {
              (uint256 base_usd_price, uint256 oldestObservation1) = getPrice(_base, USD);
              (uint256 quote_usd_price, uint256 oldestObservation2) = getPrice(_quote, USD);
              uint256 usdc_price = base_usd_price * PRECISION / quote_usd_price;
              oldestObservation = (oldestObservation1 < oldestObservation2) ? oldestObservation1 : oldestObservation2;
              return (usdc_price, oldestObservation);
        }
        (price, oldestObservation) = _getPrice(_base, _quote);
        return (price, oldestObservation);
    }
    
    // Normalize chainlink price to 18 decimals (since any non-ETH quote only returns 8 decimals precision)
    function _getPrice(address _base, address _quote) internal view returns(uint256, uint256) {
        uint8 decimals;
        try registry.decimals(_base, _quote)
            returns (uint8 precision) {
            decimals = precision;
        } catch {
            return (0, 0);
        }
        (,int price,,uint observationTimestamp,) = registry.latestRoundData(_base, _quote);
        uint256 normalizedPrice = uint256(price) * PRECISION / (10 ** decimals);
        return (normalizedPrice, uint256(observationTimestamp));
    
    }
    
    function canUpdateTokenPrices() external pure override returns (bool) {
        return false;
    }
    
    function updateTokenPrices(address[] memory tokens) external pure override returns (bool[] memory updates) {
        return new bool[](tokens.length);
    }
    
}