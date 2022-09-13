// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interfaces/PriceFeedProxy.sol';

contract IndexHandler {
  struct IndexFeed {
    address proxy;
    uint8 weight;
  }

  struct Index {
    string name;
    uint256 weightsTotal;
    IndexFeed[] priceFeeds;
  }

  Index[] public indexes;

  function getIndexPriceFromIndex(uint256 _index)
    public
    view
    returns (uint256)
  {
    Index memory index = indexes[_index];
    uint256 priceUSD;
    for (uint256 i = 0; i < index.priceFeeds.length; i++) {
      IndexFeed memory _proxy = index.priceFeeds[i];
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxy.proxy);
      priceUSD += (_feedPriceUSD * _proxy.weight) / index.weightsTotal;
    }
    return priceUSD;
  }

  function getIndexPriceFromFeeds(
    address[] memory _proxies,
    uint8[] memory _weights,
    uint256 _totalWeight
  ) public view returns (uint256) {
    require(
      _proxies.length == _weights.length,
      'proxies and weights must be same length'
    );
    uint256 priceUSD;
    for (uint256 i = 0; i < _proxies.length; i++) {
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxies[i]);
      priceUSD += (_feedPriceUSD * _weights[i]) / _totalWeight;
    }
    return priceUSD;
  }

  function getLatestProxyInfo(address _proxy)
    public
    view
    returns (
      uint16,
      uint80,
      uint256
    )
  {
    PriceFeedProxy _feed = PriceFeedProxy(_proxy);
    uint16 _phaseId = _feed.phaseId();
    uint8 _decimals = _feed.decimals();
    (uint80 _proxyRoundId, int256 _price, , , ) = _feed.latestRoundData();
    return (
      _phaseId,
      _proxyRoundId,
      uint256(_price) * (10**18 / 10**_decimals)
    );
  }

  function getProxyPriceAtRound(address _proxy, uint80 _roundId)
    public
    view
    returns (uint256)
  {
    PriceFeedProxy _feed = PriceFeedProxy(_proxy);
    uint8 _decimals = _feed.decimals();
    (, int256 _price, , , ) = _feed.getRoundData(_roundId);
    return uint256(_price) * (10**18 / 10**_decimals);
  }

  function getHistoricalPrice(
    address _proxy,
    uint16 _phaseId,
    uint80 _aggregatorRoundId,
    bool _requireCompletion
  )
    public
    view
    returns (
      uint80,
      uint256,
      uint256,
      uint80
    )
  {
    PriceFeedProxy _proxyContract = PriceFeedProxy(_proxy);
    uint80 _proxyRoundId = _getProxyRoundId(_phaseId, _aggregatorRoundId);
    (
      uint80 _roundId,
      int256 _price,
      ,
      uint256 _timestamp,
      uint80 _answeredInRound
    ) = _proxyContract.getRoundData(_proxyRoundId);
    uint8 _decimals = _proxyContract.decimals();
    if (_requireCompletion) {
      require(_timestamp > 0, 'Round not complete');
    }
    return (
      _roundId,
      uint256(_price) * (10**18 / 10**_decimals),
      _timestamp,
      _answeredInRound
    );
  }

  function _getProxyRoundId(uint16 _phaseId, uint80 _aggregatorRoundId)
    internal
    pure
    returns (uint80)
  {
    return uint80((uint256(_phaseId) << 64) | _aggregatorRoundId);
  }

  function getAggregatorInfo(uint256 _proxyRoundId)
    public
    pure
    returns (uint16, uint64)
  {
    uint16 _phaseId = uint16(_proxyRoundId >> 64);
    uint64 _aggregatorRoundId = uint64(_proxyRoundId);
    return (_phaseId, _aggregatorRoundId);
  }
}