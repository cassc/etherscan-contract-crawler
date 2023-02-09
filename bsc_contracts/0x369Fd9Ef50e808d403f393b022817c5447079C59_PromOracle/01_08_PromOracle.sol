// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
  function decimals() external view returns (uint8);
}

contract PromOracle is AccessControl {
  bytes32 internal constant ADMIN_SETTER = keccak256("ADMIN_SETTER");

  mapping(address => uint256) public quote;
  mapping(address => address) public priceFeed;

  event QuoteUpdated(address token, uint256 quote);

  constructor(address _relayer) {
    _setupRole(ADMIN_SETTER, msg.sender);
    _setupRole(ADMIN_SETTER, _relayer);
  }

  function setPriceFeed(address _token, address _priceFeed)
    public
    onlyRole(ADMIN_SETTER)
  {
    priceFeed[_token] = _priceFeed;
  }

  function setQuotes(address[] calldata _token, uint256[] calldata _quote)
    public
    onlyRole(ADMIN_SETTER)
  {
    for (uint256 i = 0; i < _token.length; i++) {
      quote[_token[i]] = _quote[i];
      emit QuoteUpdated(_token[i], _quote[i]);
    }
  }

  //** Convert value of token A to value of token B */

  function convertTokenValue(
    address _tokenA,
    uint256 _valueA,
    address _tokenB
  ) external view returns (uint256 valueB) {
    uint256 _quoteA = getQuote(_tokenA);
    uint256 _quoteB = getQuote(_tokenB);

    valueB =
      (_valueA *
        _quoteA *
        10**((getDecimals(_tokenB) - getDecimals((_tokenA))) * 2)) /
      _quoteB;
  }

  function getDecimals(address _token) internal view returns (uint256) {
    if (_token != address(0)) {
      return IERC20(_token).decimals();
    } else {
      return 18;
    }
  }

  function getFeedAnswer(address _token) internal view returns (int256 answer) {
    (, answer, , , ) = AggregatorV3Interface(priceFeed[_token])
      .latestRoundData();
  }

  function getQuote(address _token) internal view returns (uint256 _quote) {
    if (priceFeed[_token] != address(0)) {
      _quote = uint256(getFeedAnswer(_token));
    } else if (quote[_token] != 0) {
      _quote = quote[_token];
    } else {
      revert("quote is missing");
    }
  }
}