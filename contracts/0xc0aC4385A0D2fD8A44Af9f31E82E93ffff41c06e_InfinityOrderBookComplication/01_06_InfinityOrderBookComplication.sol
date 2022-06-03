// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import 'hardhat/console.sol'; // todo: remove this

/**
 * @title InfinityOrderBookComplication
 * @notice Complication to execute orderbook orders
 */
contract InfinityOrderBookComplication is IComplication, Ownable {
  using OrderTypes for OrderTypes.Order;
  using OrderTypes for OrderTypes.OrderItem;

  uint256 public PROTOCOL_FEE;
  uint256 public ERROR_BOUND; // error bound for prices in wei; todo: check if this is reqd

  event NewProtocolFee(uint256 protocolFee);
  event NewErrorbound(uint256 errorBound);

  /**
   * @notice Constructor
   * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
   * @param _errorBound price error bound in wei
   */
  constructor(uint256 _protocolFee, uint256 _errorBound) {
    PROTOCOL_FEE = _protocolFee;
    ERROR_BOUND = _errorBound;
  }

  function canExecMatchOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view override returns (bool, uint256) {
    console.log('running canExecOrder in InfinityOrderBookComplication');
    bool _isTimeValid = isTimeValid(sell, buy);
    require(_isTimeValid, 'Time is not valid');
    (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);
    require(_isPriceValid, 'Price is not valid');
    bool numItemsValid = areNumItemsValid(sell, buy, constructed);
    require(numItemsValid, 'Number of items is not valid');
    bool itemsIntersect = checkItemsIntersect(sell, constructed) &&
      checkItemsIntersect(buy, constructed) &&
      checkItemsIntersect(sell, buy);
    require(itemsIntersect, 'Items do not intersect');
    // console.log('isTimeValid', isTimeValid);
    // console.log('isAmountValid', isAmountValid);
    // console.log('numItemsValid', numItemsValid);
    // console.log('itemsIntersect', itemsIntersect);
    return (true, execPrice);
    // return (
    //   isTimeValid(sell, buy) &&
    //     isPriceValid &&
    //     areNumItemsValid(sell, buy, constructed) &&
    //     checkItemsIntersect(sell, constructed) &&
    //     checkItemsIntersect(buy, constructed) &&
    //     checkItemsIntersect(sell, buy),
    //   execPrice
    // );
  }

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    override
    returns (bool, uint256)
  {
    console.log('running canExecTakeOrder in InfinityOrderBookComplication');
    // check timestamps
    (uint256 startTime, uint256 endTime) = (makerOrder.constraints[3], makerOrder.constraints[4]);
    bool _isTimeValid = startTime <= block.timestamp && endTime >= block.timestamp;
    require(_isTimeValid, 'Time is not valid');
    (uint256 currentMakerPrice, uint256 currentTakerPrice) = (
      getCurrentPrice(makerOrder),
      getCurrentPrice(takerOrder)
    );
    bool _isPriceValid = arePricesWithinErrorBound(currentMakerPrice, currentTakerPrice);
    require(_isPriceValid, 'Price is not valid');
    bool numItemsValid = areTakerNumItemsValid(makerOrder, takerOrder);
    require(numItemsValid, 'Number of items is not valid');
    bool itemsIntersect = checkItemsIntersect(makerOrder, takerOrder);
    require(itemsIntersect, 'Items do not intersect');
    // console.log('isTimeValid', isTimeValid);
    // console.log('isAmountValid', isAmountValid);
    // console.log('numItemsValid', numItemsValid);
    // console.log('itemsIntersect', itemsIntersect);
    return (true, currentTakerPrice);
    // return (
    //   makerOrder.constraints[3] <= block.timestamp &&
    //     makerOrder.constraints[4] >= block.timestamp &&
    //     isPriceValid &&
    //     areTakerNumItemsValid(makerOrder, takerOrder) &&
    //     checkItemsIntersect(makerOrder, takerOrder),
    //   currentTakerPrice
    // );
  }

  function canExecOneToMany(OrderTypes.Order calldata makerOrder, OrderTypes.Order[] calldata takerOrders)
    external
    view
    override
    returns (bool)
  {
    console.log('running canExecOneToMany in InfinityOrderBookComplication');
    uint256 numTakerItems;
    bool isTakerOrdersTimeValid = true;
    bool itemsIntersect = true;
    uint256 ordersLength = takerOrders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      if (!isTakerOrdersTimeValid || !itemsIntersect) {
        console.log('isTakerOrdersTimeValid');
        console.logBool(isTakerOrdersTimeValid);
        console.log('itemsIntersect');
        console.logBool(itemsIntersect);
        return false; // short circuit
      }

      uint256 nftsLength = takerOrders[i].nfts.length;
      for (uint256 j = 0; j < nftsLength; ) {
        numTakerItems += takerOrders[i].nfts[j].tokens.length;
        unchecked {
          ++j;
        }
      }

      isTakerOrdersTimeValid =
        isTakerOrdersTimeValid &&
        takerOrders[i].constraints[3] <= block.timestamp &&
        takerOrders[i].constraints[4] >= block.timestamp;

      itemsIntersect = itemsIntersect && checkItemsIntersect(makerOrder, takerOrders[i]);

      unchecked {
        ++i;
      }
    }
    require(itemsIntersect, 'Items do not intersect');

    bool _isTimeValid = isTakerOrdersTimeValid &&
      makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp;

    require(_isTimeValid, 'Time is not valid');

    uint256 currentMakerOrderPrice = getCurrentPrice(makerOrder);
    uint256 sumCurrentTakerOrderPrices = _sumCurrentPrices(takerOrders);
    console.log('currentMakerOrderPrice');
    console.logUint(currentMakerOrderPrice);
    console.log('sumCurrentTakerOrderPrices');
    console.logUint(sumCurrentTakerOrderPrices);
    bool _isPriceValid = false;
    if (makerOrder.isSellOrder) {
      _isPriceValid = sumCurrentTakerOrderPrices >= currentMakerOrderPrice;
    } else {
      _isPriceValid = sumCurrentTakerOrderPrices <= currentMakerOrderPrice;
    }

    require(_isPriceValid, 'Price is not valid');

    console.log('numTakerItems');
    console.logUint(numTakerItems);
    console.log('makerOrder numItems');
    console.logUint(makerOrder.constraints[0]);
    require(numTakerItems == makerOrder.constraints[0], 'Num items dont match');

    return true;
  }

  function _sumCurrentPrices(OrderTypes.Order[] calldata orders) internal view returns (uint256) {
    uint256 sum = 0;
    uint256 ordersLength = orders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      sum += getCurrentPrice(orders[i]);
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  /**
   * @notice Return protocol fee for this complication
   * @return protocol fee
   */
  function getProtocolFee() external view override returns (uint256) {
    return PROTOCOL_FEE;
  }

  // ============================================== INTERNAL FUNCTIONS ===================================================

  function isTimeValid(OrderTypes.Order calldata sell, OrderTypes.Order calldata buy) public view returns (bool) {
    (uint256 sellStartTime, uint256 sellEndTime) = (sell.constraints[3], sell.constraints[4]);
    (uint256 buyStartTime, uint256 buyEndTime) = (buy.constraints[3], buy.constraints[4]);
    bool isSellTimeValid = sellStartTime <= block.timestamp && sellEndTime >= block.timestamp;
    bool isBuyTimeValid = buyStartTime <= block.timestamp && buyEndTime >= block.timestamp;
    console.log('isSellTimeValid');
    console.logBool(isSellTimeValid);
    console.log('isBuyTimeValid');
    console.logBool(isBuyTimeValid);
    return isSellTimeValid && isBuyTimeValid;
    // return
    //   sell.constraints[3] <= block.timestamp &&
    //   sell.constraints[4] >= block.timestamp &&
    //   buy.constraints[3] <= block.timestamp &&
    //   buy.constraints[4] >= block.timestamp;
  }

  // todo: make this function public
  function isPriceValid(OrderTypes.Order calldata sell, OrderTypes.Order calldata buy)
    public
    view
    returns (bool, uint256)
  {
    (uint256 currentSellPrice, uint256 currentBuyPrice) = (getCurrentPrice(sell), getCurrentPrice(buy));
    return (currentBuyPrice >= currentSellPrice, currentBuyPrice);
  }

  function areNumItemsValid(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) public view returns (bool) {
    bool numItemsWithinBounds = constructed.constraints[0] >= buy.constraints[0] &&
      buy.constraints[0] <= sell.constraints[0];

    uint256 numConstructedItems = 0;
    uint256 nftsLength = constructed.nfts.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numConstructedItems += constructed.nfts[i].tokens.length;
        ++i;
      }
    }
    bool numConstructedItemsMatch = constructed.constraints[0] == numConstructedItems;
    console.log('numItemsWithinBounds');
    console.logBool(numItemsWithinBounds);
    console.log('numConstructedItemsMatch');
    console.logBool(numConstructedItemsMatch);
    return numItemsWithinBounds && numConstructedItemsMatch;
  }

  function areTakerNumItemsValid(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    public
    view
    returns (bool)
  {
    bool numItemsEqual = makerOrder.constraints[0] == takerOrder.constraints[0];

    uint256 numTakerItems = 0;
    uint256 nftsLength = takerOrder.nfts.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numTakerItems += takerOrder.nfts[i].tokens.length;
        ++i;
      }
    }
    bool numTakerItemsMatch = takerOrder.constraints[0] == numTakerItems;
    console.log('numItemsEqual');
    console.logBool(numItemsEqual);
    console.log('numTakerItemsMatch');
    console.logBool(numTakerItemsMatch);
    return numItemsEqual && numTakerItemsMatch;
  }

  function getCurrentPrice(OrderTypes.Order calldata order) public view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    console.log('startPrice, endPrice');
    console.logUint(startPrice);
    console.logUint(endPrice);
    (uint256 startTime, uint256 endTime) = (order.constraints[3], order.constraints[4]);
    console.log('startTime, endTime');
    console.logUint(startTime);
    console.logUint(endTime);
    console.log('block.timestamp');
    console.logUint(block.timestamp);
    uint256 duration = order.constraints[4] - order.constraints[3];
    console.log('duration');
    console.logUint(duration);
    uint256 priceDiff = startPrice > endPrice ? startPrice - endPrice : endPrice - startPrice;
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - order.constraints[3];
    console.log('elapsedTime');
    console.logUint(elapsedTime);
    uint256 PRECISION = 10**4; // precision for division; similar to bps
    uint256 portionBps = elapsedTime > duration ? PRECISION : ((elapsedTime * PRECISION) / duration);
    console.log('portion');
    console.logUint(portionBps);
    priceDiff = (priceDiff * portionBps) / PRECISION;
    console.log('priceDiff');
    console.logUint(priceDiff);
    uint256 currentPrice = startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
    console.log('current price');
    console.logUint(currentPrice);
    return currentPrice;
    // return startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
  }

  function arePricesWithinErrorBound(uint256 price1, uint256 price2) public view returns (bool) {
    // console.log('price1', price1, 'price2', price2);
    // console.log('ERROR_BOUND', ERROR_BOUND);
    if (price1 == price2) {
      return true;
    } else if (price1 > price2 && price1 - price2 <= ERROR_BOUND) {
      return true;
    } else if (price2 > price1 && price2 - price1 <= ERROR_BOUND) {
      return true;
    } else {
      return false;
    }
  }

  function checkItemsIntersect(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    public
    view
    returns (bool)
  {
    uint256 takerOrderNftsLength = takerOrder.nfts.length;
    uint256 makerOrderNftsLength = makerOrder.nfts.length;

    // case where maker/taker didn't specify any items
    if (makerOrderNftsLength == 0 || takerOrderNftsLength == 0) {
      return true;
    }

    uint256 numCollsMatched = 0;
    // check if taker has all items in maker
    for (uint256 i = 0; i < takerOrderNftsLength; ) {
      for (uint256 j = 0; j < makerOrderNftsLength; ) {
        if (makerOrder.nfts[j].collection == takerOrder.nfts[i].collection) {
          // increment numCollsMatched
          unchecked {
            ++numCollsMatched;
          }
          // check if tokenIds intersect
          bool tokenIdsIntersect = checkTokenIdsIntersect(makerOrder.nfts[j], takerOrder.nfts[i]);
          console.log('tokenIdsIntersect');
          console.logBool(tokenIdsIntersect);
          require(tokenIdsIntersect, 'taker cant have more tokenIds per coll than maker');
          // short circuit
          break;
        }
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }
    // console.log('collections intersect', numCollsMatched == takerOrder.nfts.length);
    console.logUint(numCollsMatched);
    console.logUint(takerOrderNftsLength);
    return numCollsMatched == takerOrderNftsLength;
  }

  function checkTokenIdsIntersect(OrderTypes.OrderItem calldata makerItem, OrderTypes.OrderItem calldata takerItem)
    public
    view
    returns (bool)
  {
    uint256 takerItemTokensLength = takerItem.tokens.length;
    uint256 makerItemTokensLength = makerItem.tokens.length;
    // case where maker/taker didn't specify any tokenIds for this collection
    if (makerItemTokensLength == 0 || takerItemTokensLength == 0) {
      return true;
    }
    uint256 numTokenIdsPerCollMatched = 0;
    for (uint256 k = 0; k < takerItemTokensLength; ) {
      for (uint256 l = 0; l < makerItemTokensLength; ) {
        if (
          makerItem.tokens[l].tokenId == takerItem.tokens[k].tokenId &&
          makerItem.tokens[l].numTokens == takerItem.tokens[k].numTokens
        ) {
          // increment numTokenIdsPerCollMatched
          unchecked {
            ++numTokenIdsPerCollMatched;
          }
          // short circuit
          break;
        }
        unchecked {
          ++l;
        }
      }
      unchecked {
        ++k;
      }
    }
    // console.log('token ids per collection intersect', numTokenIdsPerCollMatched == takerItem.tokens.length);
    console.logUint(numTokenIdsPerCollMatched);
    console.logUint(takerItemTokensLength);
    return numTokenIdsPerCollMatched == takerItemTokensLength;
  }

  // ====================================== ADMIN FUNCTIONS ======================================

  function setErrorBound(uint256 _errorBound) external onlyOwner {
    ERROR_BOUND = _errorBound;
    emit NewErrorbound(_errorBound);
  }

  function setProtocolFee(uint256 _protocolFee) external onlyOwner {
    PROTOCOL_FEE = _protocolFee;
    emit NewProtocolFee(_protocolFee);
  }
}