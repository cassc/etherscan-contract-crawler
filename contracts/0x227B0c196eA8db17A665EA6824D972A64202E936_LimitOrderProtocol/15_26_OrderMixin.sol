// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './helpers/AmountCalculator.sol';
import './helpers/ChainlinkCalculator.sol';
import './helpers/NonceManager.sol';
import './helpers/PredicateHelper.sol';
import './interfaces/InteractiveNotificationReceiver.sol';
import './interfaces/ILimitOrderCallee.sol';
import './libraries/ArgumentsDecoder.sol';
import './libraries/Permitable.sol';

/// @title Regular Limit Order mixin
abstract contract OrderMixin is
  EIP712,
  AmountCalculator,
  ChainlinkCalculator,
  NonceManager,
  PredicateHelper,
  Permitable,
  Ownable
{
  using Address for address;
  using ArgumentsDecoder for bytes;

  /// @notice Emitted every time order gets filled, including partial fills
  event OrderFilled(
    address indexed taker,
    bytes32 orderHash,
    uint256 remaining,
    uint256 makingAmount,
    uint256 takingAmount
  );

  /// @notice Emitted when order gets cancelled
  event OrderCanceled(address indexed maker, bytes32 orderHash, uint256 remainingRaw);

  /// @notice Emitted when update interaction target whitelist
  event UpdatedInteractionWhitelist(address _address, bool isWhitelist);

  // Fixed-size order part with core information
  struct StaticOrder {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender; // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    address feeRecipient;
    uint32 makerTokenFeePercent;
  }

  // `StaticOrder` extension including variable-sized additional order meta information
  struct Order {
    uint256 salt;
    address makerAsset;
    address takerAsset;
    address maker;
    address receiver;
    address allowedSender; // equals to Zero address on public orders
    uint256 makingAmount;
    uint256 takingAmount;
    address feeRecipient;
    uint32 makerTokenFeePercent;
    bytes makerAssetData;
    bytes takerAssetData;
    bytes getMakerAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
    bytes getTakerAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
    bytes predicate; // this.staticcall(bytes) => (bool)
    bytes permit; // On first fill: permit.1.call(abi.encodePacked(permit.selector, permit.2))
    bytes interaction;
  }

  struct FillOrderParams {
    Order order;
    bytes signature;
    uint256 makingAmount;
    uint256 takingAmount;
    uint256 thresholdAmount;
    address target;
    bytes callbackData;
  }

  struct FillBatchOrdersParams {
    Order[] orders;
    bytes[] signatures;
    uint256 takingAmount;
    uint256 thresholdAmount;
    address target;
  }

  bytes32 public constant LIMIT_ORDER_TYPEHASH =
    keccak256(
      'Order(uint256 salt,address makerAsset,address takerAsset,address maker,address receiver,address allowedSender,uint256 makingAmount,uint256 takingAmount,address feeRecipient,uint32 makerTokenFeePercent,bytes makerAssetData,bytes takerAssetData,bytes getMakerAmount,bytes getTakerAmount,bytes predicate,bytes permit,bytes interaction)'
    );
  uint256 private constant _ORDER_DOES_NOT_EXIST = 0;
  uint256 private constant _ORDER_FILLED = 1;
  uint16 internal constant BPS = 10000;

  /// @notice Stores unfilled amounts for each order plus one
  /// Therefore 0 means order doesn't exist and 1 means order was filled
  mapping(bytes32 => uint256) private _remaining;
  mapping(address => bool) interactionWhitelist;

  /// @notice Update interaction target whitelist
  function updateInteractionWhitelist(address _address, bool isWhitelist) external onlyOwner {
    interactionWhitelist[_address] = isWhitelist;
    emit UpdatedInteractionWhitelist(_address, isWhitelist);
  }

  /// @notice Returns unfilled amount for order. Throws if order does not exist
  function remaining(bytes32 orderHash) external view returns (uint256) {
    uint256 amount = _remaining[orderHash];
    require(amount != _ORDER_DOES_NOT_EXIST, 'LOP: Unknown order');
    unchecked {
      amount -= 1;
    }
    return amount;
  }

  /// @notice Returns unfilled amount for order
  /// @return Result Unfilled amount of order plus one if order exists. Otherwise 0
  function remainingRaw(bytes32 orderHash) external view returns (uint256) {
    return _remaining[orderHash];
  }

  /// @notice Same as `remainingRaw` but for multiple orders
  function remainingsRaw(bytes32[] memory orderHashes) external view returns (uint256[] memory) {
    uint256[] memory results = new uint256[](orderHashes.length);
    for (uint256 i = 0; i < orderHashes.length; i++) {
      results[i] = _remaining[orderHashes[i]];
    }
    return results;
  }

  /**
   * @notice Calls every target with corresponding data. Then reverts with CALL_RESULTS_0101011 where zeroes and ones
   * denote failure or success of the corresponding call
   * @param targets Array of addresses that will be called
   * @param data Array of data that will be passed to each call
   */
  function simulateCalls(address[] calldata targets, bytes[] calldata data) external {
    require(targets.length == data.length, 'LOP: array size mismatch');
    bytes memory reason = new bytes(targets.length);
    for (uint256 i = 0; i < targets.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = targets[i].call(data[i]);
      if (success && result.length > 0) {
        success = result.length == 32 && result.decodeBool();
      }
      reason[i] = success ? bytes1('1') : bytes1('0');
    }

    // Always revert and provide per call results
    revert(string(abi.encodePacked('CALL_RESULTS_', reason)));
  }

  /// @notice Cancels order by setting remaining amount to zero
  function cancelOrder(Order memory order) public {
    require(order.maker == msg.sender, 'LOP: Access denied');

    bytes32 orderHash = hashOrder(order);
    uint256 orderRemaining = _remaining[orderHash];
    require(orderRemaining != _ORDER_FILLED, 'LOP: already filled');
    emit OrderCanceled(msg.sender, orderHash, orderRemaining);
    _remaining[orderHash] = _ORDER_FILLED;
  }

  /// @notice Cancels multiple orders by setting remaining amount to zero
  function cancelBatchOrders(Order[] memory orders) external {
    for (uint256 i = 0; i < orders.length; ++i) {
      cancelOrder(orders[i]);
    }
  }

  /// @notice Fills an order. If one doesn't exist (first fill) it will be created using order.makerAssetData
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Making amount
  /// @param takingAmount Taking amount
  /// @param thresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
  /// @param callbackData CallbackData to callback to the msg.sender after receiving the makingAmount, the msg.sender transfer takingAmount to the maker after this call
  /// @return actualMakingAmount
  /// @return actualTakingAmount
  function fillOrder(
    Order memory order,
    bytes calldata signature,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 thresholdAmount,
    bytes calldata callbackData
  )
    external
    returns (
      uint256, /* actualMakingAmount */
      uint256 /* actualTakingAmount */
    )
  {
    return
      fillOrderTo(
        FillOrderParams(
          order,
          signature,
          makingAmount,
          takingAmount,
          thresholdAmount,
          msg.sender,
          callbackData
        ),
        false
      );
  }

  /// @notice Same as `fillOrder` but calls permit first,
  /// allowing to approve token spending and make a swap in one transaction.
  /// Also allows to specify funds destination instead of `msg.sender`
  /// @param order Order quote to fill
  /// @param signature Signature to confirm quote ownership
  /// @param makingAmount Making amount
  /// @param takingAmount Taking amount
  /// @param thresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
  /// @param target Address that will receive swap funds
  /// @param permit Should consist of abiencoded token address and encoded `IERC20Permit.permit` call.
  /// @dev See tests for examples
  function fillOrderToWithPermit(
    Order memory order,
    bytes calldata signature,
    uint256 makingAmount,
    uint256 takingAmount,
    uint256 thresholdAmount,
    address target,
    bytes calldata permit,
    bytes calldata callbackData
  )
    external
    returns (
      uint256, /* actualMakingAmount */
      uint256 /* actualTakingAmount */
    )
  {
    /* permit */
    {
      require(permit.length >= 20, 'LOP: permit length too low');
      (address token, bytes calldata permitData) = permit.decodeTargetAndData();
      _permit(token, permitData);
    }
    return
      fillOrderTo(
        FillOrderParams(
          order,
          signature,
          makingAmount,
          takingAmount,
          thresholdAmount,
          target,
          callbackData
        ),
        false
      );
  }

  /// @notice Same as `fillOrder`
  /// @param params FillOrderParams:
  ///   - Order order: quote to fill
  ///   - bytes signature: Signature to confirm quote ownership
  ///   - uint256 makingAmount: Making amount
  ///   - uint256 takingAmount: Taking amount
  ///   - uint256 thresholdAmount : Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
  ///   - address target: Maker asset recipient
  ///   - bytes callbackData: CallbackData to callback to the msg.sender after receiving the makingAmount, the msg.sender transfer takingAmount to the maker after this call
  /// @param isForcedFill if isForcedFill is true, no matter the maker's balance or allowance is not enough, still try to fill with a new makingAmount = min(makerBalance, makerAllowance)
  /// @return actualMakingAmount
  /// @return actualTakingAmount
  function fillOrderTo(FillOrderParams memory params, bool isForcedFill)
    public
    returns (
      uint256, /* actualMakingAmount */
      uint256 /* actualTakingAmount */
    )
  {
    require(params.target != address(0), 'LOP: zero target is forbidden');
    bytes32 orderHash = hashOrder(params.order);

    {
      // Stack too deep
      uint256 remainingMakerAmount = _remaining[orderHash];
      if (remainingMakerAmount == _ORDER_FILLED) return (0, 0);
      require(
        params.order.allowedSender == address(0) || params.order.allowedSender == msg.sender,
        'LOP: private order'
      );
      if (remainingMakerAmount == _ORDER_DOES_NOT_EXIST) {
        // First fill: validate order and permit maker asset
        require(
          SignatureChecker.isValidSignatureNow(params.order.maker, orderHash, params.signature),
          'LOP: bad signature'
        );
        remainingMakerAmount = params.order.makingAmount;
        if (params.order.permit.length >= 20) {
          // proceed only if permit length is enough to store address
          (address token, bytes memory permit) = params.order.permit.decodeTargetAndCalldata();
          _permitMemory(token, permit);
          require(_remaining[orderHash] == _ORDER_DOES_NOT_EXIST, 'LOP: reentrancy detected');
        }
      } else {
        unchecked {
          remainingMakerAmount -= 1;
        }
      }

      // Check if order is valid
      if (params.order.predicate.length > 0) {
        bool isValidPredicate = checkPredicate(params.order);
        if (isForcedFill) {
          if (!isValidPredicate) return (0, 0);
        } else {
          require(isValidPredicate, 'LOP: predicate returned false');
        }
      }

      // Compute maker and taker assets amount
      if ((params.takingAmount == 0) == (params.makingAmount == 0)) {
        revert('LOP: only one amount should be 0');
      } else if (params.takingAmount == 0) {
        uint256 requestedMakingAmount = params.makingAmount;
        if (params.makingAmount > remainingMakerAmount) {
          params.makingAmount = remainingMakerAmount;
        }
        /// If isForcedFill is true, set params.makingAmount = min(params.makingAmount, makerBalance, makerAllowance)
        if (isForcedFill) {
          (, params.makingAmount) = _modifyMakingAmount(
            params.order.makerAsset,
            params.order.maker,
            params.makingAmount
          );
        }

        params.takingAmount = _callGetter(
          params.order.getTakerAmount,
          params.order.makingAmount,
          params.makingAmount,
          params.order.takingAmount
        );
        // check that actual rate is not worse than what was expected
        // takingAmount / makingAmount <= thresholdAmount / requestedMakingAmount
        require(
          params.takingAmount * requestedMakingAmount <=
            params.thresholdAmount * params.makingAmount,
          'LOP: taking amount too high'
        );
      } else {
        uint256 requestedTakingAmount = params.takingAmount;
        params.makingAmount = _callGetter(
          params.order.getMakerAmount,
          params.order.takingAmount,
          params.takingAmount,
          params.order.makingAmount
        );
        /// If isForcedFill is true, set params.makingAmount = min(params.makingAmount, remainingMakerAmount, makerBalance, makerAllowance)
        bool isModified = false;
        if (isForcedFill) {
          (isModified, params.makingAmount) = _modifyMakingAmount(
            params.order.makerAsset,
            params.order.maker,
            params.makingAmount
          );
        }
        if (isModified || params.makingAmount > remainingMakerAmount) {
          params.makingAmount = params.makingAmount > remainingMakerAmount
            ? remainingMakerAmount
            : params.makingAmount;
          params.takingAmount = _callGetter(
            params.order.getTakerAmount,
            params.order.makingAmount,
            params.makingAmount,
            params.order.takingAmount
          );
        }
        // check that actual rate is not worse than what was expected
        // makingAmount / takingAmount >= thresholdAmount / requestedTakingAmount
        require(
          params.makingAmount * requestedTakingAmount >=
            params.thresholdAmount * params.takingAmount,
          'LOP: making amount too low'
        );
      }

      require(params.makingAmount > 0 && params.takingAmount > 0, "LOP: can't swap 0 amount");

      // Update remaining amount in storage
      unchecked {
        remainingMakerAmount = remainingMakerAmount - params.makingAmount;
        _remaining[orderHash] = remainingMakerAmount + 1;
      }
      emit OrderFilled(
        msg.sender,
        orderHash,
        remainingMakerAmount,
        params.makingAmount,
        params.takingAmount
      );
    }

    // Maker => FeeRecipient
    uint256 feeAmount = 0;
    if (params.order.feeRecipient != address(0) && params.order.makerTokenFeePercent > 0) {
      feeAmount = (params.makingAmount * params.order.makerTokenFeePercent + BPS - 1) / BPS;
      _makeCall(
        params.order.makerAsset,
        abi.encodePacked(
          IERC20.transferFrom.selector,
          uint256(uint160(params.order.maker)),
          uint256(uint160(params.order.feeRecipient)),
          feeAmount,
          params.order.makerAssetData
        )
      );
    }

    // Maker => Taker
    _makeCall(
      params.order.makerAsset,
      abi.encodePacked(
        IERC20.transferFrom.selector,
        uint256(uint160(params.order.maker)),
        uint256(uint160(params.target)),
        params.makingAmount - feeAmount,
        params.order.makerAssetData
      )
    );

    // Callback to msg.sender
    if (params.callbackData.length > 0) {
      ILimitOrderCallee(msg.sender).limitOrderCall(
        params.makingAmount,
        params.takingAmount,
        params.callbackData
      );
    }

    // Taker => Maker
    _makeCall(
      params.order.takerAsset,
      abi.encodePacked(
        IERC20.transferFrom.selector,
        uint256(uint160(msg.sender)),
        uint256(
          uint160(params.order.receiver == address(0) ? params.order.maker : params.order.receiver)
        ),
        params.takingAmount,
        params.order.takerAssetData
      )
    );

    // Maker can handle funds interactively
    if (params.order.interaction.length >= 20) {
      // proceed only if interaction length is enough to store address
      (address interactionTarget, bytes memory interactionData) = params
        .order
        .interaction
        .decodeTargetAndCalldata();
      require(
        interactionWhitelist[interactionTarget],
        'LOP: the interaction target is not whitelisted'
      );
      InteractiveNotificationReceiver(interactionTarget).notifyFillOrder(
        msg.sender,
        params.order.makerAsset,
        params.order.takerAsset,
        params.makingAmount,
        params.takingAmount,
        interactionData
      );
    }

    return (params.makingAmount, params.takingAmount);
  }

  /// @notice Try to fulfill the takingAmount across multiple orders that have the same makerAsset and takerAsset
  /// @param params FillBatchOrdersParams:
  ///   - Order[] orders: Order list to fill one by one until fulfill the takingAmount
  ///   - bytes[] signatures: Signatures of the orders to confirm quote ownership
  ///   - uint256 takingAmount: Taking amount
  ///   - uint256 thresholdAmount: Minimun makingAmount is acceptable
  ///   - address target: Recipient address for maker asset
  /// @return actualMakingAmount
  /// @return actualTakingAmount
  function fillBatchOrdersTo(FillBatchOrdersParams memory params)
    external
    returns (
      uint256, /* actualMakingAmount */
      uint256 /* actualTakingAmount */
    )
  {
    require(params.orders.length > 0, 'LOP: empty array');
    require(params.orders.length == params.signatures.length, 'LOP: array size mismatch');
    require(params.takingAmount != 0, 'LOP: zero takingAmount');

    address makerAsset = params.orders[0].makerAsset;
    address takerAsset = params.orders[0].takerAsset;
    uint256 actualMakingAmount = 0;
    uint256 remainingTakingAmount = params.takingAmount;
    for (uint256 i = 0; i < params.orders.length; i++) {
      require(
        makerAsset == params.orders[i].makerAsset && takerAsset == params.orders[i].takerAsset,
        'LOP: invalid pair'
      );
      (uint256 _makingAmount, uint256 _takingAmount) = fillOrderTo(
        FillOrderParams(
          params.orders[i],
          params.signatures[i],
          0,
          remainingTakingAmount,
          0,
          params.target,
          ''
        ),
        true
      );
      actualMakingAmount += _makingAmount;
      remainingTakingAmount -= _takingAmount;
      if (remainingTakingAmount == 0) break;
    }
    require(remainingTakingAmount == 0, 'LOP: cannot fulfill');
    require(actualMakingAmount >= params.thresholdAmount, 'LOP: making amount too low');
    return (actualMakingAmount, params.takingAmount);
  }

  /// @notice Checks order predicate
  function checkPredicate(Order memory order) public view returns (bool) {
    bytes memory result = address(this).functionStaticCall(
      order.predicate,
      'LOP: predicate call failed'
    );
    require(result.length == 32, 'LOP: invalid predicate return');
    return result.decodeBool();
  }

  function hashOrder(Order memory order) public view returns (bytes32) {
    StaticOrder memory staticOrder;
    assembly {
      // solhint-disable-line no-inline-assembly
      staticOrder := order
    }
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            LIMIT_ORDER_TYPEHASH,
            staticOrder,
            keccak256(order.makerAssetData),
            keccak256(order.takerAssetData),
            keccak256(order.getMakerAmount),
            keccak256(order.getTakerAmount),
            keccak256(order.predicate),
            keccak256(order.permit),
            keccak256(order.interaction)
          )
        )
      );
  }

  function _makeCall(address asset, bytes memory assetData) private {
    bytes memory result = asset.functionCall(assetData, 'LOP: asset.call failed');
    if (result.length > 0) {
      require(result.length == 32 && result.decodeBool(), 'LOP: asset.call bad result');
    }
  }

  function _callGetter(
    bytes memory getter,
    uint256 orderExpectedAmount,
    uint256 amount,
    uint256 orderResultAmount
  ) private view returns (uint256) {
    if (getter.length == 0) {
      // On empty getter calldata only exact amount is allowed
      require(amount == orderExpectedAmount, 'LOP: wrong amount');
      return orderResultAmount;
    } else {
      bytes memory result = address(this).functionStaticCall(
        abi.encodePacked(getter, amount),
        'LOP: getAmount call failed'
      );
      require(result.length == 32, 'LOP: invalid getAmount return');
      return result.decodeUint256();
    }
  }

  /// @notice Returns makingAmount = min(params.makingAmount, makerBalance, makerAllowance)
  /// @param makerAsset Maker asset address
  /// @param maker Maker address
  /// @param makingAmount Making amount
  /// @return isModified
  /// @return makingAmount
  function _modifyMakingAmount(
    address makerAsset,
    address maker,
    uint256 makingAmount
  ) private view returns (bool, uint256) {
    uint256 makerBalance = IERC20(makerAsset).balanceOf(maker);
    uint256 makerAllowance = IERC20(makerAsset).allowance(maker, address(this));

    if (makingAmount > makerBalance || makingAmount > makerAllowance) {
      makingAmount = makerBalance > makerAllowance ? makerAllowance : makerBalance;
      return (true, makingAmount);
    }

    return (false, makingAmount);
  }
}