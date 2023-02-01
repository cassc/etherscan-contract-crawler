// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./signing.sol";
import "./utils.sol";

contract OrderUtils is
    Signing
{
    /**
     * @dev Highest bit of a uint256, used to flag cancelled orders.
     */
    uint256 private constant HIGH_BIT = 1 << 255;

    /**
     * @dev Mapping from an orderHash to the filled amount in makerTokens
     * (paid by the maker) for that orderHash.
     */
    mapping(bytes32 => uint256) public makerAmountFilled;

    /**
     * @dev Order data containing a signed commitment a user made to swap tokens.
     */
    struct Order
    {
        // items contained within TYPEHASH_ORDER
        address maker;
        address makerToken;
        address takerToken;
        uint256 makerAmount;
        uint256 takerAmountMin;
        uint256 takerAmountDecayRate;
        uint256 data;
        // items NOT contained within TYPEHASH_ORDER
        bytes signature;
    }

    /**
     * @dev Status of an order depending on various events that play out.
     */
    enum OrderStatus
    {
        Invalid,
        Fillable,
        Filled,
        Canceled,
        Expired
    }
    /**
     * @dev Info about an order's status and general fillability.
     */
    struct OrderInfo
    {
        bytes32 orderHash;
        OrderStatus status;
        uint256 makerFilledAmount;
    }
    /**
     * @dev Event emitted when an order is filled.
     */
    event Fill(
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled,
        bytes32 orderHash
    );

    /**
     * @dev Event emitted when an order is canceled.
     */
    event OrderCancelled(
        bytes32 orderHash,
        address maker
    );

    constructor()
    {
    }

    /**
     * @dev Update the makerAmountFilled for the order being processed in a swap.
     */
    function _updateMakerAmountFilled(
        uint256 makerAmount,
        bytes32 orderHash,
        uint256 makerAmountToSpend,
        bool partiallyFillable
    )
        internal
    {
        // Update the fillAmount to prevent replay attacks
        // differentiate between partial fills and not allowing partial fills
        if (partiallyFillable)
        {
            uint256 newMakerAmountFilled = makerAmountFilled[orderHash] + makerAmountToSpend;
            // newMakerAmountFilled must be valid
            require(
                newMakerAmountFilled <= makerAmount,
                "RS:E2"
            );
            makerAmountFilled[orderHash] = newMakerAmountFilled;
        }
        else
        {
            // makerAmount must be valid
            require(
                makerAmountToSpend == makerAmount,
                "RS:E3"
            );
            // order must not already be filled
            require(
                makerAmountFilled[orderHash] == 0,
                "RS:E4"
            );
            // Since partial fills are not allowed, we must set this to the order's full amount
            makerAmountFilled[orderHash] = makerAmount;
        }
    }

    /**
     * @dev Get relevant order information to determine fillability of many orders.
     */
    function getOrderRelevantStatuses(
        Order[] calldata orders
    )
        external
        view
        returns (
            OrderInfo[] memory orderInfos,
            uint256[] memory makerAmountsFillable,
            bool[] memory isSignatureValids
        )
    {
        uint256 ordersLength = orders.length;
        orderInfos = new OrderInfo[](ordersLength);
        makerAmountsFillable = new uint256[](ordersLength);
        isSignatureValids = new bool[](ordersLength);
        for (uint256 i; i < ordersLength;)
        {
            // try/catches can only be used for external funciton calls
            try
                this.getOrderRelevantStatus(orders[i])
                    returns (
                        OrderInfo memory orderInfo,
                        uint256 makerAmountFillable,
                        bool isSignatureValid
                    )
            {
                orderInfos[i] = orderInfo;
                makerAmountsFillable[i] = makerAmountFillable;
                isSignatureValids[i] = isSignatureValid;
            }
            catch {}

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Get relevant order information to determine fillability of an order.
     * This function must be public because it's being called in a try catch above.
     */
    function getOrderRelevantStatus(
        Order calldata order
    )
        external
        view
        returns (
            OrderInfo memory orderInfo,
            uint256 makerAmountFillable,
            bool isSignatureValid
        )
    {
        bytes32 orderHash = getOrderHash(order);
        LibData.MakerData memory makerData = _decodeData(order.data, orderHash);
        return _validateAndGetOrderRelevantStatus(order, orderHash, makerData, false, true);
    }

    /**
     * @dev Validate an order's signature and get relevant order information to determine fillability of an order.
     * Depending on what's calling this function, we may want to revert on a failure.
     * For example, if we are swapping and something bad happens
     *     we absolutely want to revert
     * But, if we are simply making an off chain call to check the order's status and we see a bad status
     *     we do NOT want to revert because this is critical information we want to return to the off chain function caller
     * Or we may want to provide additional data (or not, to save on gas cost).
     */
    function _validateAndGetOrderRelevantStatus(
        Order calldata order,
        bytes32 orderHash,
        LibData.MakerData memory makerData,
        bool doRevertOnFailure,
        bool doGetActualFillableMakerAmount
    )
        internal
        view
        returns (
            OrderInfo memory orderInfo,
            uint256 makerAmountFillable,
            bool isSignatureValid
        )
    {
        // Tokens must be different
        require(
            order.makerToken != order.takerToken,
            "RS:E5"
        );

        // Set the various parts of orderInfo
        orderInfo.orderHash = orderHash;
        orderInfo.makerFilledAmount = makerAmountFilled[orderInfo.orderHash];

        // Determine orderInfo.status
        // The high bit will be set if the order was cancelled
        if (orderInfo.makerFilledAmount & HIGH_BIT != 0)
        {
            orderInfo.status = OrderStatus.Canceled;
        }
        // If the order has already been filled to or over the max
        else if (orderInfo.makerFilledAmount >= order.makerAmount)
        {
            orderInfo.status = OrderStatus.Filled;
        }
        // Check for expiration
        else if (makerData.expiry <= block.timestamp)
        {
            orderInfo.status = OrderStatus.Expired;
        }
        else
        {
            // If we've made it this far, the order is fillable
            orderInfo.status = OrderStatus.Fillable;
        }

        // Validate order status
        // So I have this here that will revert if it's not fillable, but i don't think i'm verifying that it's filled properly.
        // For example, right now you can doulbe fill an order. I dont think there's anything stopping that
        require(
            !doRevertOnFailure || orderInfo.status == OrderStatus.Fillable,
            "RS:E6"
        );

        // Do not calculate makerAmountFillable internally when swapping,
        // only calculate it when making external calls checking the status of orders
        // This is critical because external parties care about this information
        // but when swapping tokens we do not, and not calling this saves a lot of gas
        // If when swapping tokens, the transaction were to fail because someone doesn't have an allowance,
        // we just let it fail and bubble up an exception elsewhere, this is a great gas optimization
        if (doGetActualFillableMakerAmount)
        {
            makerAmountFillable = _getMakerAmountFillable(order, orderInfo);
        }

        // Validate order signature against the signer
        address signer = _recoverOrderSignerFromOrderHash(orderInfo.orderHash, makerData.signingScheme, order.signature);

        // Order signer must be either the order's maker or the maker's valid signer
        // Gas optimization
        // We fist compare the order.maker and signer, before considering calling isValidOrderSigner()
        // isValidOrderSigner will read from storage which incurs a large gas cost
        isSignatureValid =
            signer != address(0) &&
            (
                (order.maker == signer) ||
                isValidOrderSigner(order.maker, signer)
            );

        require(
            !doRevertOnFailure || isSignatureValid,
            "RS:E7"
        );
    }

    /**
     * @dev Calculate the actual order fillability based on maker allowance, balances, etc
     */
    function _getMakerAmountFillable(
        Order calldata order,
        OrderInfo memory orderInfo
    )
        private
        view
        returns (uint256 makerAmountFillable)
    {
        if (orderInfo.status != OrderStatus.Fillable)
        {
            // Not fillable
            return 0;
        }
        if (order.makerAmount == 0)
        {
            // Empty order
            return 0;
        }

        // It is critical to have already returned above if the order is NOT fillable
        // because certain statuses like the canceled status modifies the makerFilledAmount value
        // which would mess up the below logic.
        // So we must not proceed with the below logic if any bits in makerFilledAmount
        // have been set by order cancels or something similiar

        // Get the fillable maker amount based on the order quantities and previously filled amount
        makerAmountFillable = order.makerAmount - orderInfo.makerFilledAmount;

        // Clamp it to the amount of maker tokens we can spend on behalf of the maker
        makerAmountFillable = Math.min(
            makerAmountFillable,
            _getSpendableERC20BalanceOf(IERC20(order.makerToken), order.maker)
        );
    }

    /**
     * @dev Get spendable balance considering allowance.
     */
    function _getSpendableERC20BalanceOf(
        IERC20 token,
        address owner
    )
        internal
        view
        returns (uint256 spendableERC20BalanceOf)
    {
        spendableERC20BalanceOf = Math.min(
            token.allowance(owner, address(this)),
            token.balanceOf(owner)
        );
    }

    /**
     * @dev Decode order data into its individual components.
     */
    function _decodeData(
        uint256 data,
        bytes32 orderHash
    )
        internal
        pure
        returns (LibData.MakerData memory makerData)
    {
        // Bits
        // 0 -> 63    = begin
        // 64 -> 127  = expiry
        // 128        = partiallyFillable
        // 129 -> 130 = signingScheme
        // 131 -> ... = reserved, must be zero

        uint256 begin = uint256(uint64(data));
        uint256 expiry = uint256(uint64(data >> 64));
        bool partiallyFillable = data & 0x100000000000000000000000000000000 != 0;
        // NOTE: Take advantage of the fact that Solidity will revert if the
        // following expression does not produce a valid enum value. This means
        // we check here that the leading reserved bits must be 0.
        LibSignatures.Scheme signingScheme = LibSignatures.Scheme(data >> 129);

        // Do not allow orders where begin comes after expiry
        // This doesn't make sense on a UI/UX level and leads to exceptions with our logic
        require(
            expiry >= begin,
            "RS:E27"
        );

        // Measure maker's pre-trade balance
        makerData = LibData.MakerData(
            orderHash,
            0,
            0,
            begin,
            expiry,
            partiallyFillable,
            signingScheme
        );
    }

    /**
     * @dev Cancel multiple orders. The caller must be the maker or a valid order signer.
     * Silently succeeds if the order has already been cancelled.
     */
    function cancelOrders__tYNw(
        Order[] calldata orders
    )
        external
    {
        for (uint256 i; i < orders.length;)
        {
            // Must be either the order's maker or the maker's valid signer
            if (orders[i].maker != msg.sender &&
                !isValidOrderSigner(orders[i].maker, msg.sender))
            {
                revert("RS:E20");
            }

            bytes32 orderHash = getOrderHash(orders[i]);
            // Set the high bit on the makerAmountFilled to indicate a cancel.
            // It's okay to cancel twice.
            makerAmountFilled[orderHash] |= HIGH_BIT;
            emit OrderCancelled(orderHash, orders[i].maker);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }
}