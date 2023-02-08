// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract OKLGFaaSTimePricing is Ownable {
  AggregatorV3Interface internal priceFeed;

  uint256 public timePeriodDays = 30; // don't convert to seconds because we calc against blocksPerDay below
  uint256 public priceUSDPerTimePeriod18 = 300 * 10**18;
  uint256 public blocksPerDay;

  constructor(address _linkPriceFeedContract, uint256 _blocksPerDay) {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    priceFeed = AggregatorV3Interface(_linkPriceFeedContract);
    blocksPerDay = _blocksPerDay;
  }

  function payForPool(uint256 _tokenSupply, uint256 _perBlockAllocation)
    external
    payable
  {
    uint256 _blockLifespan = _tokenSupply / _perBlockAllocation;
    uint256 _costUSD18 = (priceUSDPerTimePeriod18 * _blockLifespan) /
      timePeriodDays /
      blocksPerDay;
    uint256 _costWei = getProductCostWei(_costUSD18);
    if (_costWei == 0) {
      return;
    }
    require(msg.value >= _costWei, 'not enough ETH to pay for service');
    (bool success, ) = payable(owner()).call{ value: msg.value }('');
    require(success, 'could not pay for pool');
  }

  function getProductCostWei(uint256 _productCostUSD18)
    public
    view
    returns (uint256)
  {
    // adding back 18 decimals to get returned value in wei
    return (10**18 * _productCostUSD18) / _getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function _getLatestETHPrice() internal view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function setTimePeriodDays(uint256 _days) external onlyOwner {
    timePeriodDays = _days;
  }

  function setPriceUSDPerTimePeriod18(uint256 _priceUSD18) external onlyOwner {
    priceUSDPerTimePeriod18 = _priceUSD18;
  }

  function setBlocksPerDay(uint256 _blocks) external onlyOwner {
    blocksPerDay = _blocks;
  }
}