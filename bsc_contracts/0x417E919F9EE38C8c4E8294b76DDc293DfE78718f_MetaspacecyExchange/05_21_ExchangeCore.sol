// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20.sol";
import "../../access/Ownable.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../utils/EIP712.sol";
import "../../utils/libraries/Market.sol";
import "../../utils/libraries/SaleKindInterface.sol";
import "../../utils/libraries/ArrayUtils.sol";
import "../../utils/libraries/ECDSA.sol";
import "../../utils/math/SafeMath.sol";
import "../proxy/OwnableDelegateProxy.sol";
import "../proxy/ProxyRegistry.sol";
import "../proxy/TokenTransferProxy.sol";
import "../proxy/AuthenticatedProxy.sol";

contract ExchangeCore is ReentrancyGuard, Ownable, EIP712 {
    using SafeMath for uint256;

    bytes32 private constant _ORDER_TYPEHASH = keccak256(
        "Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 makerProtocolFee,uint256 takerProtocolFee,address feeRecipient,uint8 feeMethod,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes callData,bytes replacementPattern,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt)"
    );

    uint256 public constant INVERSE_BASIS_POINT = 10000;
    IERC20 public exchangeToken;
    ProxyRegistry public registry;
    TokenTransferProxy public tokenTransferProxy;

    mapping(bytes32 => bool) public cancelledOrFinalized;
    mapping(bytes32 => bool) public approvedOrders;

    uint256 public minimumMakerProtocolFee = 0;
    uint256 public minimumTakerProtocolFee = 0;
    address public protocolFeeRecipient;

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        uint256 makerProtocolFee,
        uint256 takerProtocolFee,
        address indexed feeRecipient,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        Market.HowToCall howToCall,
        bytes callData,
        bytes replacementPattern,
        address staticTarget,
        bytes staticExtradata,
        address paymentToken,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        address indexed collection,
        address paymentToken,
        uint256 price
    );

    function transferTokens(address token, address from, address to, uint256 amount) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    function chargeProtocolFee(address from, address to, uint256 amount) internal {
        transferTokens(address(exchangeToken), from, to, amount);
    }

    function staticCall(address target, bytes memory callData, bytes memory extradata)
        public
        view
        returns (bool result)
    {
        bytes memory combined = new bytes(callData.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, callData);
        assembly {
            result := staticcall(gas(), target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }

    function hashOrder(Market.Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = 768;
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.target);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.callData));
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.replacementPattern));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.staticExtradata));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function hashToSign(Market.Order memory order)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashOrder(order));
    }

    function requireValidOrder(Market.Order memory order, Market.Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return hash;
    }

    function validateOrderParameters(Market.Order memory order)
        internal
        view
        returns (bool)
    {
        if (order.exchange != address(this)) {
            return false;
        }

        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

        if (order.feeMethod == Market.FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee ||
            order.takerProtocolFee < minimumTakerProtocolFee)) {
            return false;
        }

        return true;
    }

    function validateOrder(bytes32 hash, Market.Order memory order, Market.Sig memory sig) 
        internal
        view
        returns (bool)
    {
        if (!validateOrderParameters(order)) {
            return false;
        }

        if (cancelledOrFinalized[hash]) {
            return false;
        }
        
        if (approvedOrders[hash]) {
            return true;
        }
        if (ECDSA.recover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }
        return false;
    }

    function approveOrder(Market.Order memory order, bool orderbookInclusionDesired)
        internal
    {
        require(_msgSender() == order.maker);

        bytes32 hash = hashToSign(order);

        require(!approvedOrders[hash]);

        approvedOrders[hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerRelayerFee, order.takerRelayerFee, order.makerProtocolFee, order.takerProtocolFee, order.feeRecipient, order.feeMethod, order.side, order.saleKind, order.target);
        }
        {
            emit OrderApprovedPartTwo(hash, order.howToCall, order.callData, order.replacementPattern, order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
        }
    }

    function cancelOrder(Market.Order memory order, Market.Sig memory sig)
        internal
    {
        bytes32 hash = requireValidOrder(order, sig);

        require(_msgSender() == order.maker);

        cancelledOrFinalized[hash] = true;

        emit OrderCancelled(hash);
    }

    function calculateCurrentPrice(Market.Order memory order)
        internal
        view
        returns (uint256)
    {
        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.extra, order.listingTime, order.expirationTime);
    }

    function calculateMatchPrice(Market.Order memory buy, Market.Order memory sell)
        view
        internal
        returns (uint256)
    {
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(sell.side, sell.saleKind, sell.basePrice, sell.extra, sell.listingTime, sell.expirationTime);

        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(buy.side, buy.saleKind, buy.basePrice, buy.extra, buy.listingTime, buy.expirationTime);

        require(buyPrice >= sellPrice);

        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    function executeFundsTransfer(Market.Order memory buy, Market.Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {

            require(sell.takerRelayerFee <= buy.takerRelayerFee);

            if (sell.feeMethod == Market.FeeMethod.SplitFee) {
                require(sell.takerProtocolFee <= buy.takerProtocolFee);

                if (sell.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(SafeMath.mul(sell.makerRelayerFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, makerRelayerFee);
                        payable(address(sell.feeRecipient)).transfer(makerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, sell.feeRecipient, makerRelayerFee);
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(SafeMath.mul(sell.takerRelayerFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(requiredAmount, takerRelayerFee);
                        payable(address(sell.feeRecipient)).transfer(takerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, sell.feeRecipient, takerRelayerFee);
                    }
                }

                if (sell.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(SafeMath.mul(sell.makerProtocolFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, makerProtocolFee);
                        payable(address(protocolFeeRecipient)).transfer(makerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, makerProtocolFee);
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(SafeMath.mul(sell.takerProtocolFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(requiredAmount, takerProtocolFee);
                        payable(address(protocolFeeRecipient)).transfer(takerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, takerProtocolFee);
                    }
                }

            } else {
                if (sell.makerRelayerFee > 0) {
                    chargeProtocolFee(sell.maker, sell.feeRecipient, sell.makerRelayerFee);
                }
                if (sell.takerRelayerFee > 0) {
                    chargeProtocolFee(buy.maker, sell.feeRecipient, sell.takerRelayerFee);
                }
            }
        } else {

            require(buy.takerRelayerFee <= sell.takerRelayerFee);

            if (sell.feeMethod == Market.FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));

                require(buy.takerProtocolFee <= sell.takerProtocolFee);

                if (buy.makerRelayerFee > 0) {
                    transferTokens(sell.paymentToken, buy.maker, buy.feeRecipient, SafeMath.div(SafeMath.mul(buy.makerRelayerFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.takerRelayerFee > 0) {
                    transferTokens(sell.paymentToken, sell.maker, buy.feeRecipient, SafeMath.div(SafeMath.mul(buy.takerRelayerFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.makerProtocolFee > 0) {
                    transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, SafeMath.div(SafeMath.mul(buy.makerProtocolFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.takerProtocolFee > 0) {
                    transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, SafeMath.div(SafeMath.mul(buy.takerProtocolFee, price), INVERSE_BASIS_POINT));
                }

            } else {
                if (buy.makerRelayerFee > 0) {
                    chargeProtocolFee(buy.maker, buy.feeRecipient, buy.makerRelayerFee);
                }
                if (buy.takerRelayerFee > 0) {
                    chargeProtocolFee(sell.maker, buy.feeRecipient, buy.takerRelayerFee);
                }
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            payable(address(sell.maker)).transfer(receiveAmount);
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                payable(address(buy.maker)).transfer(diff);
            }
        }

        return price;
    }

    function ordersCanMatch(Market.Order memory buy, Market.Order memory sell)
        internal
        view
        returns (bool)
    {
        return (
            (buy.side == Market.Side.Buy && sell.side == Market.Side.Sell) &&
            (buy.feeMethod == sell.feeMethod) &&
            (buy.paymentToken == sell.paymentToken) &&
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) || (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
            (buy.target == sell.target) &&
            (buy.howToCall == sell.howToCall) &&
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }

    function atomicMatch(
        Market.Order memory buy,
        Market.Sig memory buySig,
        Market.Order memory sell,
        Market.Sig memory sellSig,
        bytes32 metadata
    )
        internal
        nonReentrant()
    {
        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == _msgSender()) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == _msgSender()) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }
        
        require(ordersCanMatch(buy, sell));

        uint256 size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);
      
        if (buy.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buy.callData, sell.callData, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sell.callData, buy.callData, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.callData, sell.callData));

        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        require(address(delegateProxy) != address(0));

        require(delegateProxy.implementation() == registry.delegateProxyImplementation());

        AuthenticatedProxy proxy = AuthenticatedProxy(payable(address(delegateProxy)));

        if (_msgSender() != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (_msgSender() != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        uint256 price = executeFundsTransfer(buy, sell);

        require(proxy.proxy(sell.target, sell.howToCall, sell.callData));

        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.callData, buy.staticExtradata));
        }

        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.callData, sell.staticExtradata));
        }

        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            sell.target,
            sell.paymentToken,
            price
        );
    }
}