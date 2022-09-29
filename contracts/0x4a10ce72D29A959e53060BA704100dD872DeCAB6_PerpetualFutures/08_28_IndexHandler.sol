// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './interfaces/PriceFeedProxy.sol';

contract IndexHandler {
  uint256 constant FACTOR = 10**18;

  struct IndexFeed {
    address proxy;
    uint16 weight;
    uint256 priceWeightMult;
  }

  struct Index {
    string name;
    uint256 weightsTotal;
    uint256 dowOpenMin;
    uint256 dowOpenMax;
    uint256 hourOpenMin;
    uint256 hourOpenMax;
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
      priceUSD += _proxy.priceWeightMult == 0
        ? _feedPriceUSD
        : (_feedPriceUSD * _proxy.priceWeightMult) / FACTOR;
    }
    return priceUSD;
  }

  function getIndexPriceFromFeeds(
    address[] memory _proxies,
    uint256[] memory _multipliers
  ) public view returns (uint256) {
    require(_proxies.length == _multipliers.length);
    uint256 priceUSD;
    for (uint256 i = 0; i < _proxies.length; i++) {
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxies[i]);
      priceUSD += _proxies.length == 1
        ? _feedPriceUSD
        : (_feedPriceUSD * _multipliers[i]) / FACTOR;
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
}