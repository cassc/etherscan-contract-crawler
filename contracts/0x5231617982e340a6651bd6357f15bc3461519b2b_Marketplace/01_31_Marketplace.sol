// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {OrderType} from "./utils/Enums.sol";
import {Order} from "./utils/Structs.sol";

import "./utils/OrderFulfiller.sol";
import "./utils/Operator.sol";
import "./utils/MerkleTree.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Marketplace is ReentrancyGuard, Operator, OrderFulfiller {
    /**
     * @dev Emits an event whenever an order is fulfilled.
     * @param orderHash        Hash of the fulfilled order.
     * @param buyer            Buyer of order.
     * @param seller           Seller of order.
     * @param purchasedAmount  Amount of fulfillment's for an order.
     */
    event Buy(
        bytes32 indexed orderHash,
        address indexed buyer,
        address indexed seller,
        uint256 purchasedAmount
    );

    /**
     * @dev Emitted when the seller cancels his order
     * @param orderHash  Hash of the fulfilled order.
     * @param seller     Seller of order.
     */
    event Cancel(bytes32 indexed orderHash, address indexed seller);

    // order nonce
    mapping(bytes32 => uint256) public nonce;

    constructor(address operator) {
        addOperator(operator);
    }

    function name() public pure returns (string memory) {
        return "Liquidifty Marketplace";
    }

    /**
     * @dev Retrieve an order nonce.
     * @param order The components of the order.
     */
    function orderNonce(Order calldata order) external view returns (uint256) {
        return nonce[getOrderHash(order)];
    }

    /**
     * @dev Attempt to fulfill a deal (list of orders).
     * @param orders        List of orders to fulfill
     * @param expiredAt     expiration date of the transaction
     * @param dealSign      orders signed by the backend
     * @param ordersHashes  list of order hashes
     * @notice Should provide a valid sign from order creator and operator
     */
    function buy(
        Order[] calldata orders,
        uint256 expiredAt,
        bytes calldata dealSign,
        bytes32[] calldata ordersHashes
    ) external payable nonReentrant {
        require(expiredAt > block.timestamp, "Buy: the deal is expired.");
        require(
            verifyDealSign(expiredAt, dealSign, ordersHashes),
            "Buy: wrong deal signature"
        );

        for (uint256 i = 0; i < orders.length; ) {
            proceedOrder(orders[i], ordersHashes[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Cancel order
     * @notice cancels order by setting nonce to max value. After this all
     * "buy" functions would fail on this order
     * @param order order struct
     */
    function cancel(Order calldata order) external {
        require(
            order.signer == _msgSender() &&
            recoverSigner(order.rootSign, order.root) == _msgSender(),
            "Cancel: wrong sender"
        );
        bytes32 orderHash = getOrderHash(order);
        nonce[orderHash] = order.totalAmount;

        emit Cancel(orderHash, _msgSender());
    }

    /**
     * @dev Checks order validity, handles ask and bid transfers to counterparties, increments nonce
     * @param order  order struct
     */
    function proceedOrder(Order calldata order, bytes32 orderHash) internal {
        // check order expiration date
        require(
            order.expirationDate > block.timestamp,
            "ProceedOrder: order expired."
        );

        // check order amount
        require(
            order.totalAmount >= nonce[orderHash] + order.amount,
            "ProceedOrder: wrong amount"
        );

        // verify order hash
        require(
            orderHash == getOrderHash(order),
            "ProceedOrder: hashes don't match"
        );

        // verify root signature
        require(
            order.signer == recoverSigner(order.rootSign, order.root),
            "ProceedOrder: wrong root sign"
        );

        // check order merkle tree proof
        require(
            MerkleTree.verify(order.proof, order.root, orderHash),
            "ProceedOrder: invalid proof"
        );

        // increment order nonce by current amount
        nonce[orderHash] += order.amount;

        // proceed with ask part
        if (
            order.orderType == OrderType.OFFER ||
            order.orderType == OrderType.SWAP
        ) {
            fulfillOrderPart(
                order.ask,
                order.amount,
                _msgSender(),
                order.signer
            );
        }
        if (order.orderType == OrderType.SALE) {
            fulfillOrderPartWithFee(
                order.ask,
                order.bid,
                order.amount,
                _msgSender(),
                order.signer
            );
        }

        // proceed with bid part
        if (
            order.orderType == OrderType.SALE ||
            order.orderType == OrderType.SWAP
        ) {
            fulfillOrderPart(
                order.bid,
                order.amount,
                order.signer,
                _msgSender()
            );
        }
        if (order.orderType == OrderType.OFFER) {
            fulfillOrderPartWithFee(
                order.bid,
                order.ask,
                order.amount,
                order.signer,
                _msgSender()
            );
        }

        emit Buy(orderHash, _msgSender(), order.signer, order.amount);
    }

    /**
     * @dev generates a unique hash for an order
     * @param order  order struct
     */
    function getOrderHash(Order calldata order)
    internal
    pure
    returns (bytes32)
    {
        if (order.askAny && order.ask.length == 1) {
            return
                keccak256(
                    abi.encode(
                        order.bid,
                        order.ask[0].assetType,
                        order.ask[0].collection,
                        order.ask[0].amount,
                        order.totalAmount,
                        order.creationDate,
                        order.expirationDate
                    )
                );
        }

        if (order.bidAny && order.bid.length == 1) {
            return
                keccak256(
                    abi.encode(
                        order.bid[0].assetType,
                        order.bid[0].collection,
                        order.bid[0].amount,
                        order.ask,
                        order.totalAmount,
                        order.creationDate,
                        order.expirationDate
                    )
                );
        }

        return
            keccak256(
                abi.encode(
                    order.bid,
                    order.ask,
                    order.totalAmount,
                    order.creationDate,
                    order.expirationDate
                )
            );
    }

    /**
     * @dev verify that the deal signature is made by an operator
     * @param expiredAt     expiration date of the deal
     * @param dealSign      orders signed by the backend
     * @param ordersHashes  list of orders hashes
     */
    function verifyDealSign(
        uint256 expiredAt,
        bytes calldata dealSign,
        bytes32[] calldata ordersHashes
    ) internal view returns (bool) {
        bytes32 dealHash = keccak256(
            abi.encode(expiredAt, address(this), block.chainid, ordersHashes)
        );
        return isOperator(recoverSigner(dealSign, dealHash));
    }

    /**
     * @dev return address that signed bytes32 hash
     * @param signature  65 bytes of signature
     * @param hash       hash that signed
     */
    function recoverSigner(bytes memory signature, bytes32 hash)
    internal
    pure
    returns (address)
    {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature);
    }
}