// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {SignatureChecker} from '../libs/SignatureChecker.sol';
import {IFeeManager} from '../interfaces/IFeeManager.sol';

// external imports
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title InfinityExchange

NFTNFTNFT...........................................NFTNFTNFT
NFTNFT                                                 NFTNFT
NFT                                                       NFT
.                                                           .
.                                                           .
.                                                           .
.                                                           .
.               NFTNFTNFT            NFTNFTNFT              .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.           NFTNFTNFTNFTNFTNFT   NFTNFTNFTNFTNFTNFT         .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.          NFTNFTNFTNFTNFTNFTN   NFTNFTNFTNFTNFTNFT         .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.               NFTNFTNFT            NFTNFTNFT              .
.                                                           .
.                                                           .
.                                                           .
.                                                           .
NFT                                                       NFT
NFTNFT                                                 NFTNFT
NFTNFTNFT...........................................NFTNFTNFT 

*/
contract InfinityExchange is ReentrancyGuard, Ownable {
  using OrderTypes for OrderTypes.Order;
  using OrderTypes for OrderTypes.OrderItem;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _currencies;
  EnumerableSet.AddressSet private _complications;

  address public immutable WETH;
  address public CREATOR_FEE_MANAGER;
  address public MATCH_EXECUTOR;
  bytes32 public immutable DOMAIN_SEPARATOR;

  mapping(address => uint256) public userMinOrderNonce;
  mapping(address => mapping(uint256 => bool)) public isUserOrderNonceExecutedOrCancelled;

  event CancelAllOrders(address user, uint256 newMinNonce);
  event CancelMultipleOrders(address user, uint256[] orderNonces);
  event CurrencyAdded(address currencyRegistry);
  event ComplicationAdded(address complicationRegistry);
  event CurrencyRemoved(address currencyRegistry);
  event ComplicationRemoved(address complicationRegistry);
  event NewMatchExecutor(address matchExecutor);
  event FeeSent(address collection, address currency, uint256 totalFees); // todo: is this reqd?

  event OrderFulfilled(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    address complication, // address of the complication that defines the execution
    address currency, // token address of the transacting currency
    OrderTypes.OrderItem[] nfts, // nfts sold; todo: check actual output
    uint256 amount // amount spent on the order
  );

  constructor(
    address _WETH,
    address _matchExecutor,
    address _creatorFeeManager
  ) {
    // Calculate the domain separator
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('InfinityExchange'),
        keccak256(bytes('1')), // for versionId = 1
        block.chainid,
        address(this)
      )
    );
    WETH = _WETH;
    MATCH_EXECUTOR = _matchExecutor;
    CREATOR_FEE_MANAGER = _creatorFeeManager;
  }

  fallback() external payable {}

  receive() external payable {}

  // =================================================== USER FUNCTIONS =======================================================

  /**
   * @notice Cancel all pending orders
   * @param minNonce minimum user nonce
   */
  function cancelAllOrders(uint256 minNonce) external {
    require(minNonce > userMinOrderNonce[msg.sender], 'nonce too low');
    require(minNonce < userMinOrderNonce[msg.sender] + 1000000, 'too many');
    userMinOrderNonce[msg.sender] = minNonce;
    emit CancelAllOrders(msg.sender, minNonce);
  }

  /**
   * @notice Cancel multiple orders
   * @param orderNonces array of order nonces
   */
  function cancelMultipleOrders(uint256[] calldata orderNonces) external {
    uint256 numNonces = orderNonces.length;
    require(numNonces > 0, 'cannot be empty');

    for (uint256 i = 0; i < numNonces; ) {
      require(orderNonces[i] > userMinOrderNonce[msg.sender], 'nonce too low');
      require(!isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]], 'nonce already executed or cancelled');
      isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
      unchecked {
        ++i;
      }
    }
    emit CancelMultipleOrders(msg.sender, orderNonces);
  }

  function matchOrders(
    OrderTypes.Order[] calldata sells,
    OrderTypes.Order[] calldata buys,
    OrderTypes.Order[] calldata constructs
  ) external nonReentrant {
    uint256 startGas = gasleft();
    uint256 numSells = sells.length;
    require(msg.sender == MATCH_EXECUTOR, 'only match executor can call this');
    require(numSells == buys.length && numSells == constructs.length, 'mismatched lengths');
    for (uint256 i = 0; i < numSells; ) {
      uint256 startGasPerOrder = gasleft() + ((startGas - gasleft()) / numSells);
      _matchOrders(sells[i], buys[i], constructs[i]);
      // refund gas to match executor
      _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, buys[i].signer);
      unchecked {
        ++i;
      }
    }
  }

  function takeOrders(OrderTypes.Order[] calldata makerOrders, OrderTypes.Order[] calldata takerOrders)
    external
    payable
    nonReentrant
  {
    uint256 ordersLength = makerOrders.length;
    require(ordersLength == takerOrders.length, 'mismatched lengths');

    for (uint256 i = 0; i < ordersLength; ) {
      _takeOrders(makerOrders[i], takerOrders[i]);
      unchecked {
        ++i;
      }
    }
  }

  function matchOneToManyOrders(OrderTypes.Order calldata makerOrder, OrderTypes.Order[] calldata takerOrders)
    external
    payable
    nonReentrant
  {
    uint256 startGas = gasleft();
    require(msg.sender == MATCH_EXECUTOR, 'only match executor can call this');
    address complication = makerOrder.execParams[0];
    require(_complications.contains(complication), 'complication not met');
    require(IComplication(complication).canExecOneToMany(makerOrder, takerOrders), 'cannot execute');

    bytes32 makerOrderHash = _hash(makerOrder);
    if (makerOrder.isSellOrder) {
      uint256 ordersLength = takerOrders.length;
      for (uint256 i = 0; i < ordersLength; ) {
        // 20000 for the SSTORE op that updates maker nonce status
        uint256 startGasPerOrder = gasleft() + ((startGas + 20000 - gasleft()) / ordersLength);
        _matchOneToManyOrders(false, makerOrderHash, makerOrder, takerOrders[i]);
        _refundMatchExecutionGasFeeFromBuyer(startGasPerOrder, takerOrders[i].signer);
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
    } else {
      uint256 ordersLength = takerOrders.length;
      for (uint256 i = 0; i < ordersLength; ) {
        _matchOneToManyOrders(true, makerOrderHash, takerOrders[i], makerOrder);
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;
      _refundMatchExecutionGasFeeFromBuyer(startGas, makerOrder.signer);
    }
  }

  function transferMultipleNFTs(address to, OrderTypes.OrderItem[] calldata items) external nonReentrant {
    _transferMultipleNFTs(msg.sender, to, items);
  }

  // ====================================================== VIEW FUNCTIONS ======================================================

  /**
   * @notice Check whether user order nonce is executed or cancelled
   * @param user address of user
   * @param nonce nonce of the order
   */
  function isNonceValid(address user, uint256 nonce) external view returns (bool) {
    return !isUserOrderNonceExecutedOrCancelled[user][nonce] && nonce > userMinOrderNonce[user];
  }

  function verifyOrderSig(OrderTypes.Order calldata order) external view returns (bool) {
    // Verify the validity of the signature

    (bytes32 r, bytes32 s, uint8 v) = abi.decode(order.sig, (bytes32, bytes32, uint8));

    return SignatureChecker.verify(_hash(order), order.signer, r, s, v, DOMAIN_SEPARATOR);
  }

  function verifyMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) public view returns (bool, uint256) {
    bool sidesMatch = sell.isSellOrder && !buy.isSellOrder;
    bool complicationsMatch = sell.execParams[0] == buy.execParams[0];
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);
    bool sellOrderValid = _isOrderValid(sell, sellOrderHash);
    bool buyOrderValid = _isOrderValid(buy, buyOrderHash);
    (bool executionValid, uint256 execPrice) = IComplication(sell.execParams[0]).canExecMatchOrder(
      sell,
      buy,
      constructed
    );

    return (
      sidesMatch && complicationsMatch && currenciesMatch && sellOrderValid && buyOrderValid && executionValid,
      execPrice
    );
  }

  function verifyTakeOrders(
    bytes32 makerOrderHash,
    OrderTypes.Order calldata maker,
    OrderTypes.Order calldata taker
  ) public view returns (bool, uint256) {
    bool msgSenderIsTaker = msg.sender == taker.signer;
    bool sidesMatch = (maker.isSellOrder && !taker.isSellOrder) || (!maker.isSellOrder && taker.isSellOrder);
    bool complicationsMatch = maker.execParams[0] == taker.execParams[0];
    bool currenciesMatch = maker.execParams[1] == taker.execParams[1];
    bool makerOrderValid = _isOrderValid(maker, makerOrderHash);
    (bool executionValid, uint256 execPrice) = IComplication(maker.execParams[0]).canExecTakeOrder(maker, taker);

    return (
      msgSenderIsTaker && sidesMatch && complicationsMatch && currenciesMatch && makerOrderValid && executionValid,
      execPrice
    );
  }

  function verifyOneToManyOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy
  ) public view returns (bool) {
    bool sidesMatch = sell.isSellOrder && !buy.isSellOrder;
    bool complicationsMatch = sell.execParams[0] == buy.execParams[0];
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);
    bool sellOrderValid = _isOrderValid(sell, sellOrderHash);
    bool buyOrderValid = _isOrderValid(buy, buyOrderHash);

    return (sidesMatch && complicationsMatch && currenciesMatch && sellOrderValid && buyOrderValid);
  }

  function numCurrencies() external view returns (uint256) {
    return _currencies.length();
  }

  function getCurrencyAt(uint256 index) external view returns (address) {
    return _currencies.at(index);
  }

  function isValidCurrency(address currency) external view returns (bool) {
    return _currencies.contains(currency);
  }

  function numComplications() external view returns (uint256) {
    return _complications.length();
  }

  function getComplicationAt(uint256 index) external view returns (address) {
    return _complications.at(index);
  }

  function isValidComplication(address complication) external view returns (bool) {
    return _complications.contains(complication);
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  function _matchOrders(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);

    // if this order is not valid, just return and continue with other orders
    (bool orderVerified, uint256 execPrice) = verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy, constructed);
    if (!orderVerified) {
      return (address(0), address(0), address(0), 0);
    }

    return _execMatchOrders(sellOrderHash, buyOrderHash, sell, buy, constructed, execPrice);
  }

  function _takeOrders(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    bytes32 makerOrderHash = _hash(makerOrder);
    bytes32 takerOrderHash = _hash(takerOrder);

    // if this order is not valid, just return and continue with other orders
    (bool orderVerified, uint256 execPrice) = verifyTakeOrders(makerOrderHash, makerOrder, takerOrder);
    if (!orderVerified) {
      return (address(0), address(0), address(0), 0);
    }

    // exec order
    return _execTakeOrders(makerOrderHash, takerOrderHash, makerOrder, takerOrder, execPrice);
  }

  function _matchOneToManyOrders(
    bool isTakerSeller,
    bytes32 makerOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    bytes32 sellOrderHash = isTakerSeller ? _hash(sell) : makerOrderHash;
    bytes32 buyOrderHash = isTakerSeller ? makerOrderHash : _hash(buy);

    // if this order is not valid, just return and continue with other orders
    bool orderVerified = verifyOneToManyOrders(sellOrderHash, buyOrderHash, sell, buy);
    require(orderVerified, 'order not verified');

    return _execOneToManyOrders(isTakerSeller, sellOrderHash, buyOrderHash, sell, buy);
  }

  function _execOneToManyOrders(
    bool isTakerSeller,
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // exec order
    isTakerSeller
      ? isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[6]] = true
      : isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[6]] = true;
    return
      _doExecOneToManyOrders(
        sellOrderHash,
        buyOrderHash,
        sell.signer,
        buy.signer,
        sell.constraints[5],
        isTakerSeller ? sell : buy,
        buy.execParams[1],
        isTakerSeller ? _getCurrentPrice(sell) : _getCurrentPrice(buy)
      );
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
    uint256 portionBps = elapsedTime > duration ? 1 * PRECISION : ((elapsedTime * PRECISION) / duration);

    priceDiff = (priceDiff * portionBps) / PRECISION;

    return startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
  }

  function _doExecOneToManyOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    uint256 minBpsToSeller,
    OrderTypes.Order calldata constructed,
    address currency,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    _transferNFTsAndFees(
      seller,
      buyer,
      constructed.nfts,
      execPrice,
      currency,
      minBpsToSeller,
      constructed.execParams[0]
    );

    _emitEvent(sellOrderHash, buyOrderHash, seller, buyer, constructed, execPrice);

    return (seller, buyer, constructed.execParams[1], execPrice);
  }

  /**
   * @notice Verifies the validity of the order
   * @param order the order
   * @param orderHash computed hash of the order
   */
  function _isOrderValid(OrderTypes.Order calldata order, bytes32 orderHash) internal view returns (bool) {
    return
      _orderValidity(
        order.signer,
        order.sig,
        orderHash,
        order.execParams[0],
        order.execParams[1],
        order.constraints[6]
      );
  }

  function _orderValidity(
    address signer,
    bytes calldata sig,
    bytes32 orderHash,
    address complication,
    address currency,
    uint256 nonce
  ) internal view returns (bool) {
    bool orderExpired = isUserOrderNonceExecutedOrCancelled[signer][nonce] || nonce < userMinOrderNonce[signer];

    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32, bytes32, uint8));
    bool sigValid = SignatureChecker.verify(orderHash, signer, r, s, v, DOMAIN_SEPARATOR);

    if (
      orderExpired ||
      !sigValid ||
      signer == address(0) ||
      !_currencies.contains(currency) ||
      !_complications.contains(complication)
    ) {
      return false;
    }
    return true;
  }

  function _execMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // exec order
    return
      _execMatchOrder(
        sellOrderHash,
        buyOrderHash,
        sell.signer,
        buy.signer,
        sell.constraints[6],
        buy.constraints[6],
        sell.constraints[5],
        constructed,
        execPrice
      );
  }

  function _execTakeOrders(
    bytes32 makerOrderHash,
    bytes32 takerOrderHash,
    OrderTypes.Order calldata makerOrder,
    OrderTypes.Order calldata takerOrder,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // exec order
    bool isTakerSell = takerOrder.isSellOrder;
    if (isTakerSell) {
      return _execTakerSellOrder(takerOrderHash, makerOrderHash, takerOrder, makerOrder, execPrice);
    } else {
      return _execTakerBuyOrder(takerOrderHash, makerOrderHash, takerOrder, makerOrder, execPrice);
    }
  }

  function _execTakerSellOrder(
    bytes32 takerOrderHash,
    bytes32 makerOrderHash,
    OrderTypes.Order calldata takerOrder,
    OrderTypes.Order calldata makerOrder,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;

    _transferNFTsAndFees(
      takerOrder.signer,
      makerOrder.signer,
      takerOrder.nfts,
      execPrice,
      takerOrder.execParams[1],
      takerOrder.constraints[5],
      takerOrder.execParams[0]
    );

    _emitEvent(takerOrderHash, makerOrderHash, takerOrder.signer, makerOrder.signer, takerOrder, execPrice);

    return (takerOrder.signer, makerOrder.signer, takerOrder.execParams[1], execPrice);
  }

  function _execTakerBuyOrder(
    bytes32 takerOrderHash,
    bytes32 makerOrderHash,
    OrderTypes.Order calldata takerOrder,
    OrderTypes.Order calldata makerOrder,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[6]] = true;

    _transferNFTsAndFees(
      makerOrder.signer,
      takerOrder.signer,
      takerOrder.nfts,
      execPrice,
      takerOrder.execParams[1],
      makerOrder.constraints[5],
      takerOrder.execParams[0]
    );

    _emitEvent(makerOrderHash, takerOrderHash, makerOrder.signer, takerOrder.signer, takerOrder, execPrice);

    return (makerOrder.signer, takerOrder.signer, takerOrder.execParams[1], execPrice);
  }

  function _execMatchOrder(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    uint256 sellNonce,
    uint256 buyNonce,
    uint256 minBpsToSeller,
    OrderTypes.Order calldata constructed,
    uint256 execPrice
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // Update order execution status to true (prevents replay)
    isUserOrderNonceExecutedOrCancelled[seller][sellNonce] = true;
    isUserOrderNonceExecutedOrCancelled[buyer][buyNonce] = true;

    _transferNFTsAndFees(
      seller,
      buyer,
      constructed.nfts,
      execPrice,
      constructed.execParams[1],
      minBpsToSeller,
      constructed.execParams[0]
    );

    _emitEvent(sellOrderHash, buyOrderHash, seller, buyer, constructed, execPrice);

    return (seller, buyer, constructed.execParams[1], execPrice);
  }

  function _emitEvent(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    OrderTypes.Order calldata constructed,
    uint256 amount
  ) internal {
    emit OrderFulfilled(
      sellOrderHash,
      buyOrderHash,
      seller,
      buyer,
      constructed.execParams[0],
      constructed.execParams[1],
      constructed.nfts,
      amount
    );
  }

  function _transferNFTsAndFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication
  ) internal {
    // transfer NFTs
    _transferMultipleNFTs(seller, buyer, nfts);
    // transfer fees
    _transferFees(seller, buyer, nfts, amount, currency, minBpsToSeller, complication);
  }

  function _transferMultipleNFTs(
    address from,
    address to,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    uint256 numNfts = nfts.length;
    for (uint256 i = 0; i < numNfts; ) {
      _transferNFTs(from, to, nfts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Transfer NFT
   * @param from address of the sender
   * @param to address of the recipient
   * @param item item to transfer
   */
  function _transferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    if (IERC165(item.collection).supportsInterface(0x80ac58cd)) {
      _transferERC721s(from, to, item);
    } else if (IERC165(item.collection).supportsInterface(0xd9b67a26)) {
      _transferERC1155s(from, to, item);
    }
  }

  function _transferERC721s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    uint256 numTokens = item.tokens.length;
    for (uint256 i = 0; i < numTokens; ) {
      IERC721(item.collection).safeTransferFrom(from, to, item.tokens[i].tokenId);
      unchecked {
        ++i;
      }
    }
  }

  function _transferERC1155s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    uint256 numTokens = item.tokens.length;
    for (uint256 i = 0; i < numTokens; ) {
      IERC1155(item.collection).safeTransferFrom(from, to, item.tokens[i].tokenId, item.tokens[i].numTokens, '');
      unchecked {
        ++i;
      }
    }
  }

  function _transferFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication
  ) internal {
    // creator fee
    uint256 totalFees = _sendFeesToCreators(complication, buyer, nfts, amount, currency);

    // protocol fee
    totalFees += _sendFeesToProtocol(complication, buyer, amount, currency);

    // check min bps to seller is met

    uint256 remainingAmount = amount - totalFees;

    require((remainingAmount * 10000) >= (minBpsToSeller * amount), 'Fees: Higher than expected');

    // ETH
    if (currency == address(0)) {
      require(msg.value >= amount, 'insufficient amount sent');
      // transfer amount to seller
      (bool sent, ) = seller.call{value: remainingAmount}('');
      require(sent, 'failed to send ether to seller');
    } else {
      // transfer final amount (post-fees) to seller
      IERC20(currency).safeTransferFrom(buyer, seller, remainingAmount);
    }

    // emit events
    // uint256 numNfts = nfts.length;
    // for (uint256 i = 0; i < numNfts; ) {
    //   // fee allocated per collection is simply totalFee divided by number of collections in the order
    //   emit FeeSent(nfts[i].collection, currency, totalFees / numNfts);
    //   unchecked {
    //     ++i;
    //   }
    // }
  }

  function _sendFeesToCreators(
    address execComplication,
    address buyer,
    OrderTypes.OrderItem[] calldata items,
    uint256 amount,
    address currency
  ) internal returns (uint256) {
    uint256 creatorsFee = 0;
    IFeeManager feeManager = IFeeManager(CREATOR_FEE_MANAGER);
    uint256 numItems = items.length;
    for (uint256 h = 0; h < numItems; ) {
      (address feeRecipient, uint256 feeAmount) = feeManager.calcFeesAndGetRecipient(
        execComplication,
        items[h].collection,
        amount / numItems // amount per collection on avg
      );
      if (feeRecipient != address(0) && feeAmount != 0) {
        if (currency == address(0)) {
          // transfer amount to fee recipient
          (bool sent, ) = feeRecipient.call{value: feeAmount}('');
          require(sent, 'failed to send creator fee to creator');
        } else {
          IERC20(currency).safeTransferFrom(buyer, feeRecipient, feeAmount);
        }
        creatorsFee += feeAmount;
      }
      unchecked {
        ++h;
      }
    }

    return creatorsFee;
  }

  function _sendFeesToProtocol(
    address complication,
    address buyer,
    uint256 amount,
    address currency
  ) internal returns (uint256) {
    uint256 protocolFeeBps = IComplication(complication).getProtocolFee();
    uint256 protocolFee = (protocolFeeBps * amount) / 10000;
    if (currency == address(0)) {
      // transfer amount to protocol
      (bool sent, ) = address(this).call{value: protocolFee}('');
      require(sent, 'failed to send protocol fee to protocol');
    } else {
      IERC20(currency).safeTransferFrom(buyer, address(this), protocolFee);
    }
    return protocolFee;
  }

  function _refundMatchExecutionGasFeeFromBuyer(uint256 startGas, address buyer) internal {
    // todo: check weth transfer gas cost
    uint256 gasCost = (startGas - gasleft() + 30000) * tx.gasprice;

    IERC20(WETH).safeTransferFrom(buyer, MATCH_EXECUTOR, gasCost);
  }

  function _hash(OrderTypes.Order calldata order) internal pure returns (bytes32) {
    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 ORDER_HASH = 0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;
    bytes32 orderHash = keccak256(
      abi.encode(
        ORDER_HASH,
        order.isSellOrder,
        order.signer,
        keccak256(abi.encodePacked(order.constraints)),
        _nftsHash(order.nfts),
        keccak256(abi.encodePacked(order.execParams)),
        keccak256(order.extraParams)
      )
    );

    return orderHash;
  }

  function _nftsHash(OrderTypes.OrderItem[] calldata nfts) internal pure returns (bytes32) {
    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')

    bytes32 ORDER_ITEM_HASH = 0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;
    uint256 numNfts = nfts.length;
    bytes32[] memory hashes = new bytes32[](numNfts);

    for (uint256 i = 0; i < numNfts; ) {
      bytes32 hash = keccak256(abi.encode(ORDER_ITEM_HASH, nfts[i].collection, _tokensHash(nfts[i].tokens)));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 nftsHash = keccak256(abi.encodePacked(hashes));

    return nftsHash;
  }

  function _tokensHash(OrderTypes.TokenInfo[] calldata tokens) internal pure returns (bytes32) {
    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')

    bytes32 TOKEN_INFO_HASH = 0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;
    uint256 numTokens = tokens.length;
    bytes32[] memory hashes = new bytes32[](numTokens);

    for (uint256 i = 0; i < numTokens; ) {
      bytes32 hash = keccak256(abi.encode(TOKEN_INFO_HASH, tokens[i].tokenId, tokens[i].numTokens));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 tokensHash = keccak256(abi.encodePacked(hashes));

    return tokensHash;
  }

  // ====================================================== ADMIN FUNCTIONS ======================================================

  function rescueTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).safeTransfer(destination, amount);
  }

  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: msg.value}('');
    require(sent, 'failed');
  }

  function addCurrency(address _currency) external onlyOwner {
    _currencies.add(_currency);
    emit CurrencyAdded(_currency);
  }

  function addComplication(address _complication) external onlyOwner {
    _complications.add(_complication);
    emit ComplicationAdded(_complication);
  }

  function removeCurrency(address _currency) external onlyOwner {
    _currencies.remove(_currency);
    emit CurrencyRemoved(_currency);
  }

  function removeComplication(address _complication) external onlyOwner {
    _complications.remove(_complication);
    emit ComplicationRemoved(_complication);
  }

  function updateMatchExecutor(address _matchExecutor) external onlyOwner {
    MATCH_EXECUTOR = _matchExecutor;
    emit NewMatchExecutor(_matchExecutor);
  }
}