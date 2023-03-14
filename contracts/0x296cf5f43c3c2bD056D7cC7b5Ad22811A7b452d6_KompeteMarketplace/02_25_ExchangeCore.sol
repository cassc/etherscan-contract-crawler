// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IFactory.sol";

abstract contract ExchangeCore is ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    error InvalidOrder();
    error InvalidTarget();
    error InvalidOrderParameters();
    error NonMatchableOrders();
    error NotAuthorized();
    error InvalidCollection();
    error InvalidSender();
    error AlreadyApproved();

    bytes32 private immutable _ORDER_TYPEHASH;
    
    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    /* The token used to pay exchange fees. */
    IERC20 public exchangeToken;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    /* Note that the maker's nonce at the time of approval **plus one** is stored in the mapping. */
    mapping(bytes32 => uint256) private _approvedOrdersByNonce;

    /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
    // The current nonce for the maker represents the only valid nonce that can be signed by the maker
    // If a signature was signed with a nonce that's different from the one stored in nonces, it
    // will fail validation.
    mapping(address => uint256) public nonces;

    /* List of allowed collections */
    mapping(address => bool) public allowedCollections;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    enum OrderSide {
        Buy,
        Sell
    }

    enum CollectionType {
        ERC721,
        ERC1155
    }

    /* An order on the exchange. */
    struct Order {
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker protocol fee of the order, unused for taker order. */
        uint256 makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint256 takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Side (buy/sell). */
        OrderSide side;
        /* Target collection type. */
        CollectionType collectionType;
        /* Factory for mint. */
        address mintFactory;
        /* Target collection. */
        address collection;
        /* TokenIds to transfer. */
        uint256[] tokenIds;
        /* Amount of tokenIds to transfer (ERC1155). */
        uint256[] amounts;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Extra parameter - reserved */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    event OrderApproved(bytes32 indexed hash, Order order, bool orderbookInclusionDesired);

    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        uint256 price,
        bytes32 indexed metadata
    );
    event NonceIncremented(address indexed maker, uint256 newNonce);

    constructor() {
        bytes32 typeHash = keccak256(
            "Order(address maker,address taker,uint256 makerProtocolFee,uint256 takerProtocolFee,address feeRecipient,uint8 side,uint8 collectionType,address mintFactory,address collection,uint256[] tokenIds,uint256[] amounts,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt,uint256 nonce)"
        );
        _ORDER_TYPEHASH = typeHash;
    }

    /**
     * Increment a particular maker's nonce, thereby invalidating all orders that were not signed
     * with the original nonce.
     */
    function incrementNonce() external {
        uint256 newNonce = ++nonces[msg.sender];
        emit NonceIncremented(msg.sender, newNonce);
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @param nonce maker nonce to hash
     * @return hash Hash of order
     */
    function hashOrder(Order memory order, uint256 nonce) internal view returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(_ORDER_TYPEHASH),
                    abi.encode(
                        order.maker,
                        order.taker,
                        order.makerProtocolFee,
                        order.takerProtocolFee,
                        order.feeRecipient,
                        order.side
                    ),
                    abi.encode(order.collectionType, order.mintFactory, order.collection),
                    keccak256(abi.encodePacked(order.tokenIds)),
                    keccak256(abi.encodePacked(order.amounts)),
                    abi.encode(
                        order.paymentToken,
                        order.basePrice,
                        order.extra,
                        order.listingTime,
                        order.expirationTime,
                        order.salt
                    ),
                    abi.encode(nonce)
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @param nonce Nonce to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order, uint256 nonce) internal view returns (bytes32) {
        return _hashTypedDataV4(hashOrder(order, nonce));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param nonce Nonce to validate
     * @param signature ECDSA signature
     */
    function requireValidOrder(
        Order memory order,
        bytes memory signature,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order, nonce);
        if (!validateOrder(hash, order, signature)) revert InvalidOrder();
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order) internal view returns (bool) {
        /* Order must have a maker. */
        if (order.maker == address(0)) {
            return false;
        }

        if (order.tokenIds.length == 0 || order.tokenIds.length != order.amounts.length) {
            return false;
        }

        if (order.mintFactory != address(0) && !allowedCollections[order.mintFactory]) {
            return false;
        }

        if (order.collection == address(0) || !allowedCollections[order.collection]) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param signature ECDSA signature
     */
    function validateOrder(
        bytes32 hash,
        Order memory order,
        bytes memory signature
    ) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Return true if order has been previously approved with the current nonce */
        uint256 approvedOrderNoncePlusOne = _approvedOrdersByNonce[hash];
        if (approvedOrderNoncePlusOne != 0) {
            return approvedOrderNoncePlusOne == nonces[order.maker] + 1;
        }
        /* validate signature. */
        return SignatureChecker.isValidSignatureNow(order.maker, hash, signature);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime) internal view returns (bool) {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Determine if an order has been approved. Note that the order may not still
     * be valid in cases where the maker's nonce has been incremented.
     * @param hash Hash of the order
     * @return approved whether or not the order was approved.
     */
    function approvedOrders(bytes32 hash) public view returns (bool approved) {
        return _approvedOrdersByNonce[hash] != 0;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired) internal {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        if (msg.sender != order.maker) revert InvalidSender();

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, nonces[order.maker]);

        /* Assert order has not already been approved. */
        if (_approvedOrdersByNonce[hash] != 0) revert AlreadyApproved();

        /* EFFECTS */

        /* Mark order as approved. */
        _approvedOrdersByNonce[hash] = nonces[order.maker] + 1;

        emit OrderApproved(hash, order, orderbookInclusionDesired);
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param nonce Nonce to cancel
     * @param signature ECDSA signature
     */
    function cancelOrder(
        Order memory order,
        bytes memory signature,
        uint256 nonce
    ) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, signature, nonce);

        /* Assert sender is authorized to cancel order. */
        if (msg.sender != order.maker) revert NotAuthorized();

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell) internal pure returns (uint256) {
        /* Calculate sell price. */
        uint256 sellPrice = sell.basePrice;

        /* Calculate buy price. */
        uint256 buyPrice = buy.basePrice;

        /* Require price cross. */
        require(buyPrice >= sellPrice);

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell) internal returns (uint256) {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        uint256 makerProtocolFee;
        uint256 takerProtocolFee;

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerProtocolFee <= buy.takerProtocolFee);

            /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */

            if (sell.makerProtocolFee > 0) {
                makerProtocolFee = SafeMath.div(SafeMath.mul(sell.makerProtocolFee, price), INVERSE_BASIS_POINT);
                if (sell.paymentToken == address(0)) {
                    receiveAmount = SafeMath.sub(receiveAmount, makerProtocolFee);
                    payable(protocolFeeRecipient).transfer(makerProtocolFee);
                } else {
                    transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, makerProtocolFee);
                }
            }

            if (sell.takerProtocolFee > 0) {
                takerProtocolFee = SafeMath.div(SafeMath.mul(sell.takerProtocolFee, price), INVERSE_BASIS_POINT);
                if (sell.paymentToken == address(0)) {
                    requiredAmount = SafeMath.add(requiredAmount, takerProtocolFee);
                    payable(protocolFeeRecipient).transfer(takerProtocolFee);
                } else {
                    transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, takerProtocolFee);
                }
            }
        } else {
            /* Buy-side order is maker. */

            /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
            require(sell.paymentToken != address(0));

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerProtocolFee <= sell.takerProtocolFee);

            if (buy.makerProtocolFee > 0) {
                makerProtocolFee = SafeMath.div(SafeMath.mul(buy.makerProtocolFee, price), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, makerProtocolFee);
            }

            if (buy.takerProtocolFee > 0) {
                takerProtocolFee = SafeMath.div(SafeMath.mul(buy.takerProtocolFee, price), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, takerProtocolFee);
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            payable(sell.maker).transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                payable(buy.maker).transfer(diff);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    /**
     * @dev Execute all ERC721/ERC1155 token transfers associated with an order match
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeTokensTransfer(Order memory buy, Order memory sell) internal {
        if (sell.collectionType == CollectionType.ERC721) {
            if (sell.mintFactory != address(0)) {
                if (sell.tokenIds.length == 1) {
                    IERC721Factory(sell.mintFactory).mint(
                        buy.maker,
                        sell.tokenIds[0],
                        ""
                    );
                } else {
                    IERC721Factory(sell.mintFactory).mintBatch(
                        buy.maker,
                        sell.tokenIds,
                        ""
                    );
                }
            } else {
                for (uint256 i = 0; i < sell.tokenIds.length; i++) {
                    require(sell.amounts[i] == 1, "Invalid amount");
                    IERC721(sell.collection).safeTransferFrom(sell.maker, buy.maker, sell.tokenIds[i], "");
                }
            }
        } else if (sell.collectionType == CollectionType.ERC1155) {
            if (sell.mintFactory != address(0)) {
                if (sell.tokenIds.length == 1) {
                    IERC1155Factory(sell.mintFactory).mint(
                        buy.maker,
                        sell.tokenIds[0],
                        sell.amounts[0],
                        ""
                    );
                } else {
                    IERC1155Factory(sell.mintFactory).mintBatch(
                        buy.maker,
                        sell.tokenIds,
                        sell.amounts,
                        ""
                    );
                }
            } else {
                if (sell.tokenIds.length == 1) {
                    IERC1155(sell.collection).safeTransferFrom(
                        sell.maker,
                        buy.maker,
                        sell.tokenIds[0],
                        sell.amounts[0],
                        ""
                    );
                } else {
                    IERC1155(sell.collection).safeBatchTransferFrom(
                        sell.maker,
                        buy.maker,
                        sell.tokenIds,
                        sell.amounts,
                        ""
                    );
                }
            }
        }
    }

    function uintArrayMatch(uint256[] memory a, uint256[] memory b) internal pure returns (bool) {
        if (a.length != b.length) return false;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell) internal view returns (bool) {
        return (/* Must be opposite-side. */
        (buy.side == OrderSide.Buy && sell.side == OrderSide.Sell) &&
            /* Must match tokens. */
            (buy.tokenIds.length > 0 && uintArrayMatch(buy.tokenIds, sell.tokenIds)) &&
            /* Must match amounts. */
            (sell.amounts.length == 0 || uintArrayMatch(buy.amounts, sell.amounts)) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) ||
                (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
            /* Must mint factory. */
            (buy.mintFactory == sell.mintFactory) &&
            /* Must match target. */
            (buy.collection == sell.collection) &&
            /* Buy-side order must be settleable. */
            canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            canSettleOrder(sell.listingTime, sell.expirationTime));
    }

    function canMint(address minter, address factory, address collection) internal view returns (bool) {
        bool allowed = IFactory(factory).canMint(collection, minter);
        return allowed;
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(
        Order memory buy,
        bytes memory buySig,
        Order memory sell,
        bytes memory sellSig,
        bytes32 metadata
    ) internal nonReentrant {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            if (!validateOrderParameters(buy)) revert InvalidOrderParameters();
        } else {
            buyHash = _requireValidOrderWithNonce(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            if (!validateOrderParameters(sell)) revert InvalidOrderParameters();
        } else {
            sellHash = _requireValidOrderWithNonce(sell, sellSig);
        }

        /* Must be matchable. */
        if (!ordersCanMatch(buy, sell)) revert NonMatchableOrders();

        address target = sell.mintFactory;
        if (target != address(0)) {
            /* Minter must be allowed */
            if (!canMint(sell.maker, sell.mintFactory, sell.collection)) revert NotAuthorized();
        }
        else {
            target = sell.collection;
        }

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        if (!Address.isContract(target)) revert InvalidTarget();

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);

        /* Execute tokens transfers. */
        executeTokensTransfer(buy, sell);

        /* Log match event. */
        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            price,
            metadata
        );
    }

    function _requireValidOrderWithNonce(Order memory order, bytes memory signature) internal view returns (bytes32) {
        return requireValidOrder(order, signature, nonces[order.maker]);
    }
}