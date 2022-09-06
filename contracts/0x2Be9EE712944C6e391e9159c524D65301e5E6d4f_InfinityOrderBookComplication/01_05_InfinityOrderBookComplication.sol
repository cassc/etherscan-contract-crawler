// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

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

  // ======================================================= EXTERNAL FUNCTIONS ==================================================

  function canExecMatchOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view override returns (bool, uint256) {
    (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);
    return (
      isTimeValid(sell, buy) &&
        _isPriceValid &&
        areNumItemsValid(sell, buy, constructed) &&
        doItemsIntersect(sell, constructed) &&
        doItemsIntersect(buy, constructed) &&
        doItemsIntersect(sell, buy),
      execPrice
    );
  }

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    override
    returns (bool, uint256)
  {
    (uint256 currentMakerPrice, uint256 currentTakerPrice) = (
      _getCurrentPrice(makerOrder),
      _getCurrentPrice(takerOrder)
    );
    return (
      makerOrder.constraints[3] <= block.timestamp &&
        makerOrder.constraints[4] >= block.timestamp &&
        arePricesWithinErrorBound(currentMakerPrice, currentTakerPrice) &&
        areTakerNumItemsValid(makerOrder, takerOrder) &&
        doItemsIntersect(makerOrder, takerOrder),
      currentTakerPrice
    );
  }

  function canExecOneToMany(OrderTypes.Order calldata makerOrder, OrderTypes.Order[] calldata takerOrders)
    external
    view
    override
    returns (bool)
  {
    uint256 numTakerItems;
    bool isTakerOrdersTimeValid = true;
    bool itemsIntersect = true;
    uint256 ordersLength = takerOrders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      if (!isTakerOrdersTimeValid || !itemsIntersect) {
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

      itemsIntersect = itemsIntersect && doItemsIntersect(makerOrder, takerOrders[i]);

      unchecked {
        ++i;
      }
    }

    bool _isTimeValid = isTakerOrdersTimeValid &&
      makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp;

    uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
    uint256 sumCurrentTakerOrderPrices = _sumCurrentPrices(takerOrders);

    bool _isPriceValid = false;
    if (makerOrder.isSellOrder) {
      _isPriceValid = sumCurrentTakerOrderPrices >= currentMakerOrderPrice;
    } else {
      _isPriceValid = sumCurrentTakerOrderPrices <= currentMakerOrderPrice;
    }

    return (numTakerItems == makerOrder.constraints[0]) && _isTimeValid && itemsIntersect && _isPriceValid;
  }

  // ======================================================= PUBLIC FUNCTIONS ==================================================

  function isTimeValid(OrderTypes.Order calldata sell, OrderTypes.Order calldata buy) public view returns (bool) {
    return
      sell.constraints[3] <= block.timestamp &&
      sell.constraints[4] >= block.timestamp &&
      buy.constraints[3] <= block.timestamp &&
      buy.constraints[4] >= block.timestamp;
  }

  function isPriceValid(OrderTypes.Order calldata sell, OrderTypes.Order calldata buy)
    public
    view
    returns (bool, uint256)
  {
    (uint256 currentSellPrice, uint256 currentBuyPrice) = (_getCurrentPrice(sell), _getCurrentPrice(buy));
    return (currentBuyPrice >= currentSellPrice, currentBuyPrice);
  }

  function areNumItemsValid(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) public pure returns (bool) {
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
    return numItemsWithinBounds && numConstructedItemsMatch;
  }

  function areTakerNumItemsValid(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    public
    pure
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

    return numItemsEqual && numTakerItemsMatch;
  }

  function arePricesWithinErrorBound(uint256 price1, uint256 price2) public view returns (bool) {
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

  function doItemsIntersect(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    public
    pure
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
          bool tokenIdsIntersect = doTokenIdsIntersect(makerOrder.nfts[j], takerOrder.nfts[i]);
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

    return numCollsMatched == takerOrderNftsLength;
  }

  function doTokenIdsIntersect(OrderTypes.OrderItem calldata makerItem, OrderTypes.OrderItem calldata takerItem)
    public
    pure
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

    return numTokenIdsPerCollMatched == takerItemTokensLength;
  }

  /**
   * @notice Return protocol fee for this complication
   * @return protocol fee
   */
  function getProtocolFee() external view override returns (uint256) {
    return PROTOCOL_FEE;
  }

  // ============================================== INTERNAL FUNCTIONS ===================================================

  function _sumCurrentPrices(OrderTypes.Order[] calldata orders) internal view returns (uint256) {
    uint256 sum = 0;
    uint256 ordersLength = orders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      sum += _getCurrentPrice(orders[i]);
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  function _getCurrentPrice(OrderTypes.Order calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    uint256 duration = order.constraints[4] - order.constraints[3];
    uint256 priceDiff = startPrice > endPrice ? startPrice - endPrice : endPrice - startPrice;
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - order.constraints[3];
    uint256 PRECISION = 10**4; // precision for division; similar to bps
    uint256 portionBps = elapsedTime > duration ? PRECISION : ((elapsedTime * PRECISION) / duration);
    priceDiff = (priceDiff * portionBps) / PRECISION;
    return startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
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