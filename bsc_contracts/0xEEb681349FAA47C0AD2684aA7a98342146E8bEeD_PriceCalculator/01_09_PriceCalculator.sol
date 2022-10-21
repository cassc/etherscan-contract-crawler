// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INovationRouter02.sol";
import "./interfaces/INovationPair.sol";

interface IAggregatorV3 {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

contract PriceCalculator is Ownable {

    struct PriceInfo {
        uint256 bnbPrice;
        uint256 usdPrice;
        uint256 lastUpdated;
    }

    address constant public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant public usd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD

    mapping(address => address) public tokenFeeds;

    address public unirouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    bool public isManualMode;
    mapping(address => PriceInfo) public prices;

    modifier checkManualMode {
        require(isManualMode == true, "Should be manual mode");
        _;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

    function setTokenFeed(address asset, address feed) public onlyOwner {
        tokenFeeds[asset] = feed;
    }

    function priceOf(address _token) public view returns (uint bnbPrice, uint usdPrice) {
        if (tokenFeeds[wbnb] != address(0) && tokenFeeds[_token] != address(0)) {
            (, int256 _usdPrice, , ,) = IAggregatorV3(tokenFeeds[_token]).latestRoundData();
            (, int256 _bnbPrice, , ,) = IAggregatorV3(tokenFeeds[wbnb]).latestRoundData();
            usdPrice = uint256(_usdPrice) * 1e10;
            bnbPrice = usdPrice * 1e8 / uint256(_bnbPrice);
        } else {
            uint _decimal = ERC20(_token).decimals() - 2;
            uint _padding = 10 ** 2; // tokenDecimals - usdDecimals + 2
            if (_token == wbnb) {
                bnbPrice = 1 ether;
                address[] memory route = new address[](2);
                route[0] = _token; route[1] = usd;
                usdPrice = INovationRouter02(unirouter).getAmountsOut(uint256(10 ** _decimal), route)[1] * _padding;
            } else if (_token == usd) {
                usdPrice = 1 ether;
                address[] memory route = new address[](2);
                route[0] = _token; route[1] = wbnb;
                bnbPrice = INovationRouter02(unirouter).getAmountsOut(uint256(10 ** _decimal), route)[1] * 1e2;
            } else {
                address[] memory route0 = new address[](2);
                route0[0] = _token; route0[1] = wbnb;
                address[] memory route1 = new address[](3);
                route1[0] = _token; route1[1] = wbnb; route1[2] = usd;
                bnbPrice = INovationRouter02(unirouter).getAmountsOut(uint256(10 ** _decimal), route0)[1] * 1e2;
                // usdPrice = INovationRouter02(unirouter).getAmountsOut(uint256(10 ** _decimal), route1)[2] * _padding;
                
                (, int256 _bnbUsdPrice, , ,) = IAggregatorV3(tokenFeeds[_token]).latestRoundData();
                // uint bnbUsdPrice = uint256(_usdPrice) * 1e10;
                usdPrice = bnbPrice * uint(_bnbUsdPrice) / 1e8;
            }
        }
    }

    function valueOfToken(address _token, uint _amount) public view returns (uint bnbAmount, uint usdAmount) {
        if (isManualMode == true && !(tokenFeeds[wbnb] != address(0) && tokenFeeds[_token] != address(0))) {
            bnbAmount = _amount * prices[_token].bnbPrice / 1e18;
            usdAmount = _amount * prices[_token].usdPrice / 1e18;
        } else {
            (bnbAmount, usdAmount) = _valueOfToken(_token, _amount);
        }
    }

    function valueOfLP(address _token, uint _amount) public view returns (uint bnbAmount, uint usdAmount) {
        if (isManualMode == false) {
            (bnbAmount, usdAmount) = _valueOfLP(_token, _amount);
        } else {
            bnbAmount = _amount * prices[_token].bnbPrice / 1e18;
            usdAmount = _amount * prices[_token].usdPrice / 1e18;
        }
    }

    function _valueOfToken(address _token, uint _amount) internal view returns (uint bnbAmount, uint usdAmount) {
        (uint256 _bnbPrice,uint256 _usdPrice) = priceOf(_token);
        bnbAmount = _amount * _bnbPrice / 1e18;
        usdAmount = _amount * _usdPrice / 1e18;
    }

    function _valueOfLP(address _token, uint _amount) internal view returns (uint bnbAmount, uint usdAmount) {
        INovationPair _lp = INovationPair(_token);
        address _token0 = _lp.token0();
        uint diffDecimals = 18 - ERC20(_token0).decimals();
        (uint256 _reserve0,,) = _lp.getReserves();
        (uint256 _bnbPrice,uint256 _usdPrice) = priceOf(_token0);
        bnbAmount = 2 * _amount * _bnbPrice * _reserve0 / _lp.totalSupply() / 1e18 * 10**diffDecimals;
        usdAmount = 2 * _amount * _usdPrice * _reserve0 / _lp.totalSupply() / 1e18 * 10**diffDecimals;
    }

    function setTokenPrice(address _token, uint256 _bnbPrice, uint256 _usdPrice) external checkManualMode {
        prices[_token].bnbPrice = _bnbPrice;
        prices[_token].usdPrice = _usdPrice;
        prices[_token].lastUpdated = block.timestamp;
    }

    function updateTokenPrice(address _token, bool _isLP) external checkManualMode {
        uint256 _bnbPrice = 0;
        uint256 _usdPrice = 0;
        if (_isLP == true) {
            (_bnbPrice, _usdPrice) = _valueOfLP(_token, uint256(1 ether));
        } else {
            (_bnbPrice, _usdPrice) = _valueOfToken(_token, uint256(1 ether));
        }

        prices[_token].bnbPrice = _bnbPrice;
        prices[_token].usdPrice = _usdPrice;
        prices[_token].lastUpdated = block.timestamp;
    }

    function setManualMode(bool _mode) external {
        isManualMode = _mode;
    }
}