// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./interfaces/IStakeable.sol";
import "./utils/pyth/PythStructs.sol";
import "./utils/pyth/PythParser.sol";
import "./libs/math/FixedPoint.sol";
import "./interfaces/AbstractOracleAggregator.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// we use Pyth oracle as the primary source
contract OracleAggregator is AbstractOracleAggregator, PythParser {
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  mapping(bytes32 => uint256) public confMultiplierPerPriceId;
  mapping(bytes32 => uint256) public staleThresholdPerPriceId;

  event SetConfMultiplierEvent(bytes32 priceId, uint256 confMultiplier);
  event SetStaleThresholdEvent(bytes32 priceId, uint256 staleThreshold);

  constructor(
    address owner,
    IPythWithGetters _pyth
  ) AbstractOracleAggregator(owner) PythParser(_pyth) {}

  // governance functions

  function setConfMultiplier(
    bytes32 priceId,
    uint256 confMultiplier
  ) external onlyOwner {
    confMultiplierPerPriceId[priceId] = confMultiplier;
    emit SetConfMultiplierEvent(priceId, confMultiplier);
  }

  function setStaleThreshold(
    bytes32 priceId,
    uint256 staleThreshold
  ) external onlyOwner {
    staleThresholdPerPriceId[priceId] = staleThreshold;
    emit SetStaleThresholdEvent(priceId, staleThreshold);
  }

  // external functions

  function getUpdateFee(
    uint256 updateDataSize
  ) external view override returns (uint256 feeAmount) {
    return pyth.getUpdateFee(updateDataSize);
  }

  function parsePriceFeed(
    address user,
    bytes32 priceId,
    bytes[] memory updateData
  ) external view override returns (PricePackage memory) {
    bytes32[] memory priceIds = new bytes32[](1);
    priceIds[0] = priceId;
    PythInternalPriceInfo[] memory priceFeeds = parsePriceFeedUpdates(
      updateData,
      priceIds
    );
    PythStructs.Price memory rawPrice = PythStructs.Price(
      priceFeeds[0].price,
      priceFeeds[0].conf,
      priceFeeds[0].expo,
      priceFeeds[0].publishTime
    );

    {
      (uint256 midPrice, uint256 conf) = toFixed(rawPrice);

      uint256 spread = confMultiplierPerPriceId[priceId].mulDown(conf);
      return
        _discounted(
          user,
          PricePackage(
            midPrice.add(spread).toUint128(),
            midPrice.sub(spread).toUint128(),
            rawPrice.publishTime
          )
        );
    }
  }

  function updateLatestPrice(
    address user,
    bytes32 priceId,
    bytes[] calldata priceData,
    uint256 updateFee
  ) external payable override returns (PricePackage memory) {
    bytes32[] memory priceIds = new bytes32[](1);
    priceIds[0] = priceId;

    updatePriceFeeds(priceData, priceIds, updateFee);
    return _discounted(user, _cachedPricePerPriceId[priceId]);
  }

  function updatePriceFeeds(
    bytes[] memory priceData,
    bytes32[] memory priceIds,
    uint256 updateFee
  ) public payable override {
    pyth.updatePriceFeeds{value: updateFee}(priceData);

    for (uint256 i = 0; i < priceIds.length; ++i) {
      PythStructs.Price memory rawPrice = pyth.getPriceNoOlderThan(
        priceIds[i],
        staleThresholdPerPriceId[priceIds[i]]
      );
      (uint256 midPrice, uint256 conf) = toFixed(rawPrice);
      uint256 askPrice = midPrice.add(
        confMultiplierPerPriceId[priceIds[i]].mulDown(conf)
      );
      uint256 bidPrice = midPrice.sub(
        confMultiplierPerPriceId[priceIds[i]].mulDown(conf)
      );

      (uint256 checkAskPrice, uint256 checkBidPrice) = _checkPrice(priceIds[i]);
      if (checkAskPrice > 0) {
        askPrice = askPrice.max(checkAskPrice);
      }
      if (checkBidPrice > 0) {
        bidPrice = bidPrice.min(checkBidPrice);
      }

      _cachedPricePerPriceId[priceIds[i]] = PricePackage(
        askPrice.toUint128(),
        bidPrice.toUint128(),
        rawPrice.publishTime
      );
    }
  }

  // internal functions

  function _discounted(
    address user,
    PricePackage memory price
  ) internal view returns (PricePackage memory) {
    uint256 spread = uint256(price.ask).sub(price.bid) / 2;
    uint256 _length = _ugpDiscount.length();
    for (uint256 i = 0; i < _length; ++i) {
      (address ugpAddress, uint256 ugpDiscount) = _ugpDiscount.at(i);
      if (IStakeable(ugpAddress).hasStake(user)) {
        uint256 discount = spread.mulDown(ugpDiscount);
        price.ask = uint256(price.ask).sub(discount).toUint128();
        price.bid = uint256(price.bid).add(discount).toUint128();
        return price;
      }
    }
    return price;
  }

  function toFixed(
    PythStructs.Price memory Price
  ) private pure returns (uint256 price, uint256 conf) {
    _require(Price.expo <= 0, Errors.POSITIVE_EXPO);
    _require(Price.price >= 0, Errors.NEGATIVE_PRICE);

    uint256 expo = abs(Price.expo);
    if (expo < 18) {
      return (
        abs(Price.price) * (10 ** (18 - expo)),
        Price.conf * (10 ** (18 - expo))
      );
    }
    return (
      abs(Price.price) / (10 ** (expo - 18)),
      Price.conf / (10 ** (expo - 18))
    );
  }
}