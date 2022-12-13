// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/OrderLib.sol";
import "./extensions/RecrowEscrow.sol";
import "./extensions/RecrowTxValidatable.sol";

/**
 * @title RecrowBase
 * @notice Recrow central contract, handling external user-facing operations.
 */
abstract contract RecrowBase is
    ERC2771Context,
    ReentrancyGuard,
    RecrowEscrow,
    RecrowTxValidatable
{
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OrderTypeMismatch();
    error InvalidTimeLimit();
    error InvalidOrdersLength();
    error TakerMakerMismatch();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets domain variables and trusted forwarder.
     * @param name The human-readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recrow TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    ) EIP712(name, version) ERC2771Context(trustedForwarder) {}

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start an escrow order and deposit assets.
     * @dev Assets will held in escrow until the order is finalized or canceled.
     * @param order OrderData to create.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function createOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        _validateFull(
            OrderLib.CREATE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        _createOrder(order);
    }

    /**
     * @notice Update an escrow order by cancelling the previous order and
     * creating a new one.
     * @dev Orders must be from the same parties (taker & maker).
     * @param orderUpdate An update data containing 2 orders (old & new).
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function updateOrder(
        OrderLib.OrderUpdateData calldata orderUpdate,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        if (
            orderUpdate.orderOld.taker != orderUpdate.orderNew.taker ||
            orderUpdate.orderOld.maker != orderUpdate.orderNew.maker
        ) {
            revert TakerMakerMismatch();
        }
        _validateOrder(OrderLib.UPDATE_ORDER_TYPE, orderUpdate.orderOld);
        _validateOrder(OrderLib.UPDATE_ORDER_TYPE, orderUpdate.orderNew);
        (
            bool isMakerSigValid,
            string memory makerSigErrorMessage
        ) = _validateSig(
                orderUpdate,
                orderUpdate.orderNew.maker,
                signatureLeft
            );
        if (!isMakerSigValid) {
            revert(makerSigErrorMessage);
        }
        (
            bool isTakerSigValid,
            string memory takerSigErrorMessage
        ) = _validateSig(
                orderUpdate,
                orderUpdate.orderNew.taker,
                signatureRight
            );
        if (!isTakerSigValid) {
            revert(takerSigErrorMessage);
        }
        _cancelOrder(orderUpdate.orderOld);
        _createOrder(orderUpdate.orderNew);
    }

    /**
     * @notice Cancel an escrow order, returning the deposit to taker.
     * @dev If an order has yet to be finalized after expiry `order.end`, only
     * require taker signature to cancel.
     * @param order OrderData to cancel.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function cancelOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external nonReentrant {
        if (order.end < block.timestamp) {
            _validateOrderAndSig(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                order.taker,
                signatureRight
            );
        } else {
            _validateFull(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                signatureLeft,
                signatureRight
            );
        }
        _cancelOrder(order);
    }

    /**
     * @notice Finalize an escrow order, allowing the deposit and goods to be sent.
     * @dev The designated arbitrator can finalize without requiring maker sig.
     * @param order OrderData to finalize.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function finalizeOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        _validateFull(
            OrderLib.FINALIZE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        uint256 makeAssetsLength = order.makeAssets.length;
        if (makeAssetsLength > 0) {
            for (uint256 i = 0; i <= makeAssetsLength - 1; ) {
                _transfer(
                    order.makeAssets[i],
                    order.maker,
                    order.makeAssets[i].recipient
                );

                unchecked {
                    i++;
                }
            }
        }
        uint256 extraAssetsLength = order.extraAssets.length;
        if (extraAssetsLength > 0) {
            for (uint256 i = 0; i <= extraAssetsLength - 1; ) {
                _transfer(
                    order.extraAssets[i],
                    order.maker,
                    order.extraAssets[i].recipient
                );

                unchecked {
                    i++;
                }
            }
        }
        bytes32 orderId = OrderLib.hashKey(order);
        _pay(orderId, order.takeAssets);
    }

    /**
     * @notice Get the current protocol version
     * @return The protocol version
     */
    function getVersion() external pure returns (bytes4) {
        return OrderLib.VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create an order, transferring assets to Recrow.
     * @param order OrderData to create.
     */
    function _createOrder(OrderLib.OrderData calldata order) internal {
        bytes32 orderId = OrderLib.hashKey(order);
        _createDeposit(orderId, order.taker, order.takeAssets);
    }

    /**
     * @notice Cancel an order, returning assets to taker.
     * @param order OrderData to cancel.
     */
    function _cancelOrder(OrderLib.OrderData calldata order) internal {
        bytes32 orderId = OrderLib.hashKey(order);
        _withdraw(orderId, order.taker, order.takeAssets);
    }

    /*//////////////////////////////////////////////////////////////
                            CONTEXT OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice ERC2771Context _msgSender() override
     */
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return super._msgSender();
    }

    /**
     * @notice ERC2771Context _msgData() override
     */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return super._msgData();
    }

    /*//////////////////////////////////////////////////////////////
                           VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validate order and signatures.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     * @return True if validation succeed.
     */
    function _validateFull(
        bytes4 orderType,
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) internal view returns (bool) {
        _validateOrder(orderType, order);
        (
            bool isMakerSigValid,
            string memory makerSigErrorMessage
        ) = _validateSig(order, order.maker, signatureLeft);
        if (!isMakerSigValid) {
            revert(makerSigErrorMessage);
        }
        (
            bool isTakerSigValid,
            string memory takerSigErrorMessage
        ) = _validateSig(order, order.taker, signatureRight);
        if (!isTakerSigValid && orderType != OrderLib.FINALIZE_ORDER_TYPE) {
            revert(takerSigErrorMessage);
        } else if (
            !isTakerSigValid && orderType == OrderLib.FINALIZE_ORDER_TYPE
        ) {
            (
                bool isArbitratorSigValid,
                string memory arbitratorSigErrorMessage
            ) = _validateSig(order, order.arbitrator, signatureRight);
            if (!isArbitratorSigValid) {
                revert(arbitratorSigErrorMessage);
            }
        }
        return true;
    }

    /**
     * @notice Validate order and its signature.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @param signature The signature of the order.
     * @return True if validation succeed.
     */
    function _validateOrderAndSig(
        bytes4 orderType,
        OrderLib.OrderData calldata order,
        address signer,
        bytes calldata signature
    ) internal view returns (bool) {
        _validateOrder(orderType, order);

        (bool isSigValid, string memory sigErrorMessage) = _validateSig(
            order,
            signer,
            signature
        );
        if (!isSigValid) {
            revert(sigErrorMessage);
        }
        return true;
    }

    /**
     * @notice Validate an order.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @return True if validation succeed.
     */
    function _validateOrder(bytes4 orderType, OrderLib.OrderData calldata order)
        private
        view
        returns (bool)
    {
        // We don't need to validate `start` or `end` when cancelling order
        bool isTargetOrderType = orderType != OrderLib.CANCEL_ORDER_TYPE;
        if (order.orderType != orderType) {
            revert OrderTypeMismatch();
        } else if (
            isTargetOrderType &&
            (order.start > block.timestamp || order.end < block.timestamp)
        ) {
            revert InvalidTimeLimit();
        }
        return OrderLib.validate(order);
    }

    /**
     * @notice Validate a signature.
     * @param order OrderData to check against the signature.
     * @param signer The signer of the signature.
     * @param signature The signature.
     * @return isValid True if validation succeed.
     * @return errorMessage The revert message if isValid is `false`.
     */
    function _validateSig(
        OrderLib.OrderData calldata order,
        address signer,
        bytes calldata signature
    ) private view returns (bool, string memory) {
        bytes32 hash = OrderLib.hash(order);
        (bool isValid, string memory errorMessage) = _validateTx(
            signer,
            hash,
            signature
        );
        return (isValid, errorMessage);
    }

    /**
     * @notice Validate a signature.
     * @param orderUpdate OrderUpdateData to check against the signature.
     * @param signer The signer of the signature.
     * @param signature The signature.
     * @return isValid True if validation succeed.
     * @return errorMessage The revert message if isValid is `false`.
     */
    function _validateSig(
        OrderLib.OrderUpdateData calldata orderUpdate,
        address signer,
        bytes calldata signature
    ) private view returns (bool, string memory) {
        bytes32 hash = OrderLib.hash(orderUpdate);
        (bool isValid, string memory errorMessage) = _validateTx(
            signer,
            hash,
            signature
        );
        return (isValid, errorMessage);
    }
}