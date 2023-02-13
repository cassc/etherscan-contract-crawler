// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "./ConveyorErrors.sol";
import "../lib/interfaces/token/IERC20.sol";
import "./interfaces/ILimitOrderBook.sol";
import "./interfaces/ILimitOrderSwapRouter.sol";
import "./LimitOrderSwapRouter.sol";
import "./lib/ConveyorMath.sol";
import "./interfaces/IConveyorExecutor.sol";
import "./test/utils/Console.sol";
import "./SandboxLimitOrderRouter.sol";

/// @title SandboxLimitOrderBook
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Contract to maintain active orders in limit order system.

contract SandboxLimitOrderBook is ISandboxLimitOrderBook {
    // ========================================= Immutables =============================================

    ///@notice The address of the ConveyorExecutor contract.
    address immutable LIMIT_ORDER_EXECUTOR;
    ///@notice The address of the SandboxLimitOrderRouter contract.
    address public immutable SANDBOX_LIMIT_ORDER_ROUTER;

    ///@notice The wrapped native token address.
    address immutable WETH;
    ///@notice The wrapped pegged token address.
    address immutable USDC;

    // ========================================= Constants =============================================

    ///@notice Interval that determines when an order is eligible for refresh. The interval is set to 30 days represented in Unix time.
    uint256 private constant REFRESH_INTERVAL = 2592000;
    ///@notice The minimum order value in WETH for an order to be eligible for placement.
    uint256 private constant MIN_ORDER_VALUE_IN_WETH = 10e15;

    ///@notice The fee paid every time an order is refreshed by an off-chain executor to keep the order active within the system.
    ///@notice The refresh fee is 0.02 ETH
    uint256 private constant REFRESH_FEE = 20000000000000000;

    ///@notice Minimum time between checkins.
    uint256 public constant CHECK_IN_INTERVAL = 1 days;

    // ========================================= Storage =============================================

    ///@notice State variable to track the amount of gas initally alloted during executeLimitOrders.
    uint256 minExecutionCredit;

    // ========================================= Modifiers =============================================

    ///@notice Modifier to restrict addresses other than the SandboxLimitOrderRouter from calling the contract
    modifier onlySandboxLimitOrderRouter() {
        if (msg.sender != SANDBOX_LIMIT_ORDER_ROUTER) {
            revert MsgSenderIsNotSandboxRouter();
        }
        _;
    }
    bool reentrancyStatus = false;

    ///@notice Modifier to restrict reentrancy into a function.
    modifier nonReentrant() {
        if (reentrancyStatus) {
            revert Reentrancy();
        }
        reentrancyStatus = true;
        _;
        reentrancyStatus = false;
    }

    ///@notice Temporary owner storage variable when transferring ownership of the contract.
    address tempOwner;

    ///@notice The owner of the Order Router contract
    ///@dev The contract owner can remove the owner funds from the contract, and transfer ownership of the contract.
    address owner;

    ///@notice Modifier function to only allow the owner of the contract to call specific functions
    ///@dev Functions with onlyOwner: withdrawConveyorFees, transferOwnership.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert MsgSenderIsNotOwner();
        }

        _;
    }

    // ========================================= Constructor =============================================
    ///@param _limitOrderExecutor The address of the ConveyorExecutor contract.
    ///@param _weth The address of the wrapped native token.
    ///@param _usdc The address of the wrapped pegged token.
    ///@param _minExecutionCredit The amount of gas initally alloted during executeLimitOrders.
    constructor(
        address _limitOrderExecutor,
        address _weth,
        address _usdc,
        uint256 _minExecutionCredit
    ) {
        require(
            _limitOrderExecutor != address(0),
            "limitOrderExecutor address is address(0)"
        );
        require(_minExecutionCredit != 0, "Minimum Execution Credit is 0");
        minExecutionCredit = _minExecutionCredit;
        WETH = _weth;
        USDC = _usdc;
        LIMIT_ORDER_EXECUTOR = _limitOrderExecutor;

        SANDBOX_LIMIT_ORDER_ROUTER = address(
            new SandboxLimitOrderRouter(_limitOrderExecutor, address(this))
        );

        owner = tx.origin;
    }

    // ========================================= Events =============================================

    /**@notice Event that is emitted when a new order is placed. For each order that is placed, the corresponding orderId is added
    to the orderIds param. 
     */
    event OrderPlaced(bytes32[] orderIds);

    /**@notice Event that is emitted when an order is canceled. For each order that is canceled, the corresponding orderId is added
    to the orderIds param. 
     */
    event OrderCanceled(bytes32[] orderIds);

    /**@notice Event that is emitted when a new order is update. For each order that is updated, the corresponding orderId is added
    to the orderIds param. 
     */
    event OrderUpdated(bytes32[] orderIds);

    /**@notice Event that is emitted when an order is filled. For each order that is filled, the corresponding orderId is added
    to the orderIds param. 
     */
    event OrderFilled(bytes32[] orderIds);

    /**@notice Event that is emitted when an order is partially filled. For each order that is parital filled, the corresponding orderId is added
    to the orderIds param. 
     */
    event OrderPartialFilled(
        bytes32 indexed orderId,
        uint128 indexed amountInRemaining,
        uint128 indexed amountOutRemaining,
        uint128 executionCreditRemaining,
        uint128 feeRemaining
    );

    ///@notice Event that notifies off-chain executors when an order has been refreshed.
    event OrderRefreshed(
        bytes32 indexed orderId,
        uint32 indexed lastRefreshTimestamp,
        uint32 indexed expirationTimestamp
    );

    /**@notice Event that is emitted when a an orders execution credits are updated.
     */
    event OrderExecutionCreditUpdated(
        bytes32 orderId,
        uint256 newExecutionCredit
    );

    /**@notice Event that is emitted when the minExecutionCredit Storage variable is changed by the contract owner.
     */
    event MinExecutionCreditUpdated(
        uint256 newMinExecutionCredit,
        uint256 oldMinExecutionCredit
    );

    // ========================================= Structs =============================================

    ///@notice Struct containing Order details for any limit order
    ///@param lastRefreshTimestamp - Unix timestamp representing the last time the order was refreshed.
    ///@param expirationTimestamp - Unix timestamp representing when the order should expire.
    ///@param fillPercent - The percentage filled on the initial amountInRemaining represented as 16.16 fixed point.
    ///@param price - The execution price representing the spot price of tokenIn/tokenOut that the order should be filled at. This is simply amountOutRemaining/amountInRemaining.
    ///@param executionFee - The fee paid in WETH for Order execution.
    ///@param amountOutRemaining - The exact amountOut out that the order owner is willing to accept. This value is represented in tokenOut.
    ///@param amountInRemaining - The exact amountIn of tokenIn that the order will be supplying to the contract for the limit order.
    ///@param owner - The owner of the order. This is set to the msg.sender at order placement.
    ///@param tokenIn - The tokenIn for the order.
    ///@param tokenOut - The tokenOut for the order.
    ///@param orderId - Unique identifier for the order.
    struct SandboxLimitOrder {
        uint32 lastRefreshTimestamp;
        uint32 expirationTimestamp;
        uint128 fillPercent;
        uint128 feeRemaining;
        uint128 amountInRemaining;
        uint128 amountOutRemaining;
        uint128 executionCreditRemaining;
        address owner;
        address tokenIn;
        address tokenOut;
        bytes32 orderId;
    }
    ///@notice Struct containing SandboxExecutionState details.
    ///@param sandboxLimitOrders - Array of SandboxLimitOrders to be executed.
    ///@param orderOwners - Array of order owners.
    ///@param initialTokenInBalances - Array of initial tokenIn balances for each order owner.
    ///@param initialTokenOutBalances - Array of initial tokenOut balances for each order owner.
    struct PreSandboxExecutionState {
        SandboxLimitOrder[] sandboxLimitOrders;
        address[] orderOwners;
        uint256[] initialTokenInBalances;
        uint256[] initialTokenOutBalances;
    }

    ///@notice Enum to represent the status of an order.
    ///@param None - The order is not in the system.
    ///@param PendingSandboxLimitOrder - The order is in the system and is pending execution.
    ///@param PartialFilledSandboxLimitOrder - The order is in the system and has been partially filled.
    ///@param FilledSandboxLimitOrder - The order is in the system and has been filled.
    ///@param CanceledSandboxLimitOrder - The order is in the system and has been canceled.
    enum OrderType {
        None,
        PendingSandboxLimitOrder,
        PartialFilledSandboxLimitOrder,
        FilledSandboxLimitOrder,
        CanceledSandboxLimitOrder
    }

    // ========================================= State Structures =============================================

    ///@notice Mapping from an orderId to its ordorderIdToSandboxLimitOrderer.
    mapping(bytes32 => SandboxLimitOrder) internal orderIdToSandboxLimitOrder;

    ///@notice Mapping to find the total orders quantity for a specific token, for an individual account
    ///@dev The key is represented as: keccak256(abi.encode(owner, token));
    mapping(bytes32 => uint256) public totalOrdersQuantity;

    ///@notice Mapping to check if an order exists, as well as get all the orders for an individual account.
    ///@dev ownerAddress -> orderId -> OrderType
    mapping(address => mapping(bytes32 => OrderType)) public addressToOrderIds;

    ///@notice Mapping to store the number of total orders for an individual account
    mapping(address => uint256) public totalOrdersPerAddress;

    ///@notice Mapping to store all of the orderIds for a given address including canceled, pending and fuilled orders.
    mapping(address => bytes32[]) public addressToAllOrderIds;

    ///@notice The orderNonce is a unique value is used to create orderIds and increments every time a new order is placed.
    uint256 orderNonce;

    //===========================================================================
    //====================== Order State Functions ==============================
    //===========================================================================
    function decreaseExecutionCredit(bytes32 orderId, uint128 amount)
        external
        nonReentrant
    {
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];

        if (order.orderId == bytes32(0)) {
            revert OrderDoesNotExist(order.orderId);
        }
        if (order.owner != msg.sender) {
            revert MsgSenderIsNotOrderOwner();
        }
        ///@notice Cache the credits.
        uint128 executionCreditRemaining = order.executionCreditRemaining;
        if (executionCreditRemaining < amount) {
            revert WithdrawAmountExceedsExecutionCredit(
                amount,
                executionCreditRemaining
            );
        } else {
            if (executionCreditRemaining - amount < minExecutionCredit) {
                revert InsufficientExecutionCredit(
                    executionCreditRemaining - amount,
                    minExecutionCredit
                );
            }
        }
        ///@notice Update the order execution Credit state.
        orderIdToSandboxLimitOrder[orderId].executionCreditRemaining =
            executionCreditRemaining -
            amount;
        ///@notice Pay the sender the amount withdrawed.
        _safeTransferETH(msg.sender, amount);
        emit OrderExecutionCreditUpdated(
            orderId,
            executionCreditRemaining - amount
        );
    }

    function increaseExecutionCredit(bytes32 orderId)
        external
        payable
        nonReentrant
    {
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];
        if (msg.value == 0) {
            revert InsufficientMsgValue();
        }
        if (order.orderId == bytes32(0)) {
            revert OrderDoesNotExist(order.orderId);
        }
        if (order.owner != msg.sender) {
            revert MsgSenderIsNotOrderOwner();
        }

        uint128 newExecutionCreditBalance = orderIdToSandboxLimitOrder[orderId]
            .executionCreditRemaining + uint128(msg.value);
        ///@notice Update the order execution Credit state.
        orderIdToSandboxLimitOrder[orderId]
            .executionCreditRemaining = newExecutionCreditBalance;

        emit OrderExecutionCreditUpdated(orderId, newExecutionCreditBalance);
    }

    ///@notice Places a new order of multicall type (or group of orders) into the system.
    ///@param orderGroup - List of newly created orders to be placed.
    /// @return orderIds - Returns a list of orderIds corresponding to the newly placed orders.
    function placeSandboxLimitOrder(SandboxLimitOrder[] calldata orderGroup)
        public
        payable
        returns (bytes32[] memory)
    {
        ///@notice Set the minimum credits for placement to minimumExecutionCredit * # of Orders
        uint256 minimumExecutionCreditForOrderGroup = minExecutionCredit *
            orderGroup.length;
        ///@notice Revert if the msg.value is under the minimumExecutionCreditForOrderGroup.
        if (msg.value < minimumExecutionCreditForOrderGroup) {
            revert InsufficientExecutionCredit(
                msg.value,
                minimumExecutionCreditForOrderGroup
            );
        }
        ///@notice Initialize cumulativeExecutionCredit to store the total executionCreditRemaining set through the order group.
        uint256 cumulativeExecutionCredit;
        ///@notice Initialize a new list of bytes32 to store the newly created orderIds.
        bytes32[] memory orderIds = new bytes32[](orderGroup.length);

        ///@notice Initialize the orderToken for the newly placed orders.
        /**@dev When placing a new group of orders, the tokenIn and tokenOut must be the same on each order. New orders are placed
        this way to securely validate if the msg.sender has the tokens required when placing a new order as well as enough gas credits
        to cover order execution cost.*/
        address orderToken = orderGroup[0].tokenIn;

        ///@notice Get the value of all orders on the orderToken that are currently placed for the msg.sender.
        uint256 updatedTotalOrdersValue = getTotalOrdersValue(orderToken);

        ///@notice Get the current balance of the orderToken that the msg.sender has in their account.
        uint256 tokenBalance = IERC20(orderToken).balanceOf(msg.sender);

        ///@notice For each order within the list of orders passed into the function.
        for (uint256 i = 0; i < orderGroup.length; ) {
            ///@notice Get the order details from the orderGroup.
            SandboxLimitOrder memory newOrder = orderGroup[i];

            ///@notice Increment the total value of orders by the quantity of the new order
            updatedTotalOrdersValue += newOrder.amountInRemaining;
            uint256 relativeWethValue;
            {
                ///@notice Boolean indicating if user wants to cover the fee from the fee credit balance, or by calling placeOrder with payment.
                if (!(newOrder.tokenIn == WETH)) {
                    ///@notice Calculate the spot price of the input token to WETH on Uni v2.
                    (
                        LimitOrderSwapRouter.SpotReserve[] memory spRes,

                    ) = ILimitOrderSwapRouter(LIMIT_ORDER_EXECUTOR)
                            .getAllPrices(newOrder.tokenIn, WETH, 500);
                    uint256 tokenAWethSpotPrice;
                    for (uint256 k = 0; k < spRes.length; ) {
                        if (spRes[k].spotPrice != 0) {
                            tokenAWethSpotPrice = spRes[k].spotPrice;
                            break;
                        }

                        unchecked {
                            ++k;
                        }
                    }
                    if (tokenAWethSpotPrice == 0) {
                        revert InvalidInputTokenForOrderPlacement();
                    }

                    if (!(tokenAWethSpotPrice == 0)) {
                        ///@notice Get the tokenIn decimals to normalize the relativeWethValue.
                        uint8 tokenInDecimals = IERC20(newOrder.tokenIn)
                            .decimals();
                        ///@notice Multiply the amountIn*spotPrice to get the value of the input amount in weth.
                        relativeWethValue = tokenInDecimals <= 18
                            ? ConveyorMath.mul128U(
                                tokenAWethSpotPrice,
                                newOrder.amountInRemaining
                            ) * 10**(18 - tokenInDecimals)
                            : ConveyorMath.mul128U(
                                tokenAWethSpotPrice,
                                newOrder.amountInRemaining
                            ) / 10**(tokenInDecimals - 18);
                    }
                } else {
                    relativeWethValue = newOrder.amountInRemaining;
                }

                if (relativeWethValue < MIN_ORDER_VALUE_IN_WETH) {
                    revert InsufficientOrderInputValue();
                }

                ///@notice Set the minimum fee to the fee*wethValue*subsidy.
                uint128 minFeeReceived = uint128(
                    ConveyorMath.mul64U(
                        ILimitOrderSwapRouter(LIMIT_ORDER_EXECUTOR)
                            .calculateFee(
                                uint128(relativeWethValue),
                                USDC,
                                WETH
                            ),
                        relativeWethValue
                    )
                );
                ///@notice Set the Orders min fee to be received during execution.
                newOrder.feeRemaining = minFeeReceived;
            }

            ///@notice If the newOrder's tokenIn does not match the orderToken, revert.
            if ((orderToken != newOrder.tokenIn)) {
                revert IncongruentInputTokenInOrderGroup(
                    newOrder.tokenIn,
                    orderToken
                );
            }

            ///@notice If the msg.sender does not have a sufficent balance to cover the order, revert.
            if (tokenBalance < updatedTotalOrdersValue) {
                revert InsufficientWalletBalance(
                    msg.sender,
                    tokenBalance,
                    updatedTotalOrdersValue
                );
            }

            ///@notice Create a new orderId from the orderNonce and current block timestamp
            bytes32 orderId = keccak256(
                abi.encode(orderNonce, block.timestamp)
            );

            ///@notice increment the orderNonce
            /**@dev This is unchecked because the orderNonce and block.timestamp will never be the same, so even if the 
            orderNonce overflows, it will still produce unique orderIds because the timestamp will be different.
            */
            unchecked {
                orderNonce += 2;
            }

            ///@notice Set the new order's owner to the msg.sender
            newOrder.owner = msg.sender;

            ///@notice update the newOrder's Id to the orderId generated from the orderNonce
            newOrder.orderId = orderId;

            ///@notice update the newOrder's last refresh timestamp
            ///@dev uint32(block.timestamp % (2**32 - 1)) is used to future proof the contract.
            newOrder.lastRefreshTimestamp = uint32(block.timestamp);

            ///@notice Increment the cumulative execution credit by the current orders execution.
            cumulativeExecutionCredit += newOrder.executionCreditRemaining;

            ///@notice Add the newly created order to the orderIdToOrder mapping
            orderIdToSandboxLimitOrder[orderId] = newOrder;

            ///@notice Add the orderId to the addressToOrderIds mapping
            addressToOrderIds[msg.sender][orderId] = OrderType
                .PendingSandboxLimitOrder;

            ///@notice Increment the total orders per address for the msg.sender
            ++totalOrdersPerAddress[msg.sender];

            ///@notice Add the orderId to the orderIds array for the PlaceOrder event emission and increment the orderIdIndex
            orderIds[i] = orderId;

            ///@notice Add the orderId to the addressToAllOrderIds structure
            addressToAllOrderIds[msg.sender].push(orderId);

            unchecked {
                ++i;
            }
        }

        ///@notice Assert that the cumulative execution credits == msg.value;
        if (cumulativeExecutionCredit != msg.value) {
            revert MsgValueIsNotCumulativeExecutionCredit(
                msg.value,
                cumulativeExecutionCredit
            );
        }

        ///@notice Update the total orders value on the orderToken for the msg.sender.
        _updateTotalOrdersQuantity(
            orderToken,
            msg.sender,
            updatedTotalOrdersValue
        );

        ///@notice Get the total amount approved for the ConveyorLimitOrder contract to spend on the orderToken.
        uint256 totalApprovedQuantity = IERC20(orderToken).allowance(
            msg.sender,
            address(LIMIT_ORDER_EXECUTOR)
        );

        ///@notice If the total approved quantity is less than the updatedTotalOrdersValue, revert.
        if (totalApprovedQuantity < updatedTotalOrdersValue) {
            revert InsufficientAllowanceForOrderPlacement(
                orderToken,
                totalApprovedQuantity,
                updatedTotalOrdersValue
            );
        }

        ///@notice Emit an OrderPlaced event to notify the off-chain executors that a new order has been placed.
        emit OrderPlaced(orderIds);

        return orderIds;
    }

    ///@notice Function to update a sandbox Limit Order.
    ///@param orderId - The orderId of the Sandbox Limit Order.
    ///@param amountInRemaining - The new amountInRemaining.
    ///@param amountOutRemaining - The new amountOutRemaining.
    function updateSandboxLimitOrder(
        bytes32 orderId,
        uint128 amountInRemaining,
        uint128 amountOutRemaining
    ) external payable {
        ///@notice Get the existing order that will be replaced with the new order
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];
        if (order.orderId == bytes32(0)) {
            revert OrderDoesNotExist(orderId);
        }

        if (order.owner != msg.sender) {
            revert MsgSenderIsNotOrderOwner();
        }

        ///@notice Update the executionCredits if msg.value !=0.
        if (msg.value != 0) {
            uint128 newExecutionCredit = orderIdToSandboxLimitOrder[
                order.orderId
            ].executionCreditRemaining + uint128(msg.value);
            orderIdToSandboxLimitOrder[order.orderId]
                .executionCreditRemaining = newExecutionCredit;
            emit OrderExecutionCreditUpdated(order.orderId, newExecutionCredit);
        }

        ///@notice Get the total orders value for the msg.sender on the tokenIn
        uint256 totalOrdersValue = getTotalOrdersValue(order.tokenIn);

        ///@notice Update the total orders value
        totalOrdersValue += amountInRemaining;
        totalOrdersValue -= order.amountInRemaining;

        ///@notice If the wallet does not have a sufficient balance for the updated total orders value, revert.
        if (IERC20(order.tokenIn).balanceOf(msg.sender) < totalOrdersValue) {
            revert InsufficientWalletBalance(
                msg.sender,
                IERC20(order.tokenIn).balanceOf(msg.sender),
                totalOrdersValue
            );
        }

        ///@notice Update the total orders quantity
        _updateTotalOrdersQuantity(order.tokenIn, msg.sender, totalOrdersValue);

        ///@notice Get the total amount approved for the ConveyorLimitOrder contract to spend on the orderToken.
        uint256 totalApprovedQuantity = IERC20(order.tokenIn).allowance(
            msg.sender,
            address(LIMIT_ORDER_EXECUTOR)
        );

        ///@notice If the total approved quantity is less than the newOrder.quantity, revert.
        if (totalApprovedQuantity < amountInRemaining) {
            revert InsufficientAllowanceForOrderUpdate(
                order.tokenIn,
                totalApprovedQuantity,
                amountInRemaining
            );
        }

        ///@notice Update the order details stored in the system.
        orderIdToSandboxLimitOrder[order.orderId]
            .amountInRemaining = amountInRemaining;
        orderIdToSandboxLimitOrder[order.orderId]
            .amountOutRemaining = amountOutRemaining;

        ///@notice Emit an updated order event with the orderId that was updated
        bytes32[] memory orderIds = new bytes32[](1);
        orderIds[0] = orderId;
        emit OrderUpdated(orderIds);
    }

    /// @notice cancel all orders relevant in ActiveOrders mapping to the msg.sender i.e the function caller
    function cancelOrders(bytes32[] calldata orderIds) public {
        //check that there is one or more orders
        for (uint256 i = 0; i < orderIds.length; ) {
            cancelOrder(orderIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Remove an order from the system if the order exists.
    /// @param orderId - The orderId that corresponds to the order that should be canceled.
    function cancelOrder(bytes32 orderId) public {
        ///@notice Get the order details
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];

        if (order.orderId == bytes32(0)) {
            revert OrderDoesNotExist(orderId);
        }

        if (order.owner != msg.sender) {
            revert MsgSenderIsNotOrderOwner();
        }

        ///@notice Delete the order from orderIdToOrder mapping
        delete orderIdToSandboxLimitOrder[orderId];

        ///@notice Delete the orderId from addressToOrderIds mapping
        delete addressToOrderIds[msg.sender][orderId];

        ///@notice Decrement the total orders for the msg.sender
        --totalOrdersPerAddress[msg.sender];

        ///@notice Decrement the order quantity from the total orders quantity
        decrementTotalOrdersQuantity(
            order.tokenIn,
            order.owner,
            order.amountInRemaining
        );

        ///@notice Update the status of the order to canceled
        addressToOrderIds[order.owner][order.orderId] = OrderType
            .CanceledSandboxLimitOrder;

        ///@notice Emit an event to notify the off-chain executors that the order has been canceled.
        bytes32[] memory orderIds = new bytes32[](1);
        orderIds[0] = order.orderId;
        emit OrderCanceled(orderIds);
    }

    /// @notice Function for off-chain executors to cancel an Order that does not have the minimum gas credit balance for order execution.
    /// @param orderId - Order Id of the order to cancel.
    /// @return success - Boolean to indicate if the order was successfully canceled and compensation was sent to the off-chain executor.
    function validateAndCancelOrder(bytes32 orderId)
        external
        nonReentrant
        returns (bool success)
    {
        ///@notice Get the last checkin time of the executor.
        uint256 lastCheckInTime = IConveyorExecutor(LIMIT_ORDER_EXECUTOR)
            .lastCheckIn(msg.sender);

        ///@notice Check if the last checkin time is greater than the checkin interval.
        if (block.timestamp - lastCheckInTime > CHECK_IN_INTERVAL) {
            ///@notice If the last checkin time is greater than the checkin interval, revert.
            revert ExecutorNotCheckedIn();
        }

        SandboxLimitOrder memory order = getSandboxLimitOrderById(orderId);

        ///@notice If the order owner does not have min gas credits, cancel the order
        if (
            IERC20(order.tokenIn).balanceOf(order.owner) <
            order.amountInRemaining
        ) {
            ///@notice Remove the order from the limit order system.

            ///@notice Remove the order from the limit order system.
            _safeTransferETH(
                msg.sender,
                _cancelSandboxLimitOrderViaExecutor(order)
            );

            return true;
        }

        return false;
    }

    ///@notice Remove an order from the system if the order exists.
    ///@dev This function is only called after cancel order validation and compensates the off chain executor.
    ///@param order - The order to cancel.
    function _cancelSandboxLimitOrderViaExecutor(SandboxLimitOrder memory order)
        internal
        returns (uint256 executorFee)
    {
        ///@notice Remove the order from the limit order system.
        _removeOrderFromSystem(order.orderId);

        addressToOrderIds[msg.sender][order.orderId] = OrderType
            .CanceledSandboxLimitOrder;

        uint128 executionCreditRemaining = order.executionCreditRemaining;

        ///@notice If the order owner's gas credit balance is greater than the minimum needed for a single order, send the executor the REFRESH_FEE.
        if (executionCreditRemaining > REFRESH_FEE) {
            ///@notice Decrement from the order owner's gas credit balance.
            orderIdToSandboxLimitOrder[order.orderId].executionCreditRemaining =
                executionCreditRemaining -
                uint128(REFRESH_FEE);
            executorFee = REFRESH_FEE;
            _safeTransferETH(
                order.owner,
                executionCreditRemaining - REFRESH_FEE
            );
        } else {
            ///@notice Otherwise, decrement the entire gas credit balance.
            orderIdToSandboxLimitOrder[order.orderId]
                .executionCreditRemaining = 0;
            executorFee = executionCreditRemaining;
        }

        ///@notice Emit an order canceled event to notify the off-chain exectors.
        bytes32[] memory orderIds = new bytes32[](1);
        orderIds[0] = order.orderId;
        emit OrderCanceled(orderIds);
    }

    /// @notice Function to refresh an order for another 30 days.
    /// @param orderIds - Array of order Ids to indicate which orders should be refreshed.
    function refreshOrder(bytes32[] calldata orderIds) external nonReentrant {
        ///@notice Get the last checkin time of the executor.
        uint256 lastCheckInTime = IConveyorExecutor(LIMIT_ORDER_EXECUTOR)
            .lastCheckIn(msg.sender);

        ///@notice Check if the last checkin time is greater than the checkin interval.
        if (block.timestamp - lastCheckInTime > CHECK_IN_INTERVAL) {
            ///@notice If the last checkin time is greater than the checkin interval, revert.
            revert ExecutorNotCheckedIn();
        }

        ///@notice Initialize totalRefreshFees;
        uint256 totalRefreshFees;

        ///@notice For each order in the orderIds array.
        for (uint256 i = 0; i < orderIds.length; ) {
            ///@notice Get the current orderId.
            bytes32 orderId = orderIds[i];

            ///@notice Cache the order in memory.
            SandboxLimitOrder memory order = getSandboxLimitOrderById(orderId);

            totalRefreshFees += _refreshSandboxLimitOrder(order);

            unchecked {
                ++i;
            }
        }

        ///@notice Transfer the refresh fee to off-chain executor who called the function.
        _safeTransferETH(msg.sender, totalRefreshFees);
    }

    ///@notice Internal helper function to refresh a Sandbox Limit Order.
    ///@param order - The Sandbox Limit Order to be refreshed.
    ///@return uint256 - The refresh fee to be compensated to the off-chain executor.
    function _refreshSandboxLimitOrder(SandboxLimitOrder memory order)
        internal
        returns (uint256)
    {
        uint128 executionCreditBalance = order.executionCreditRemaining;
        ///@notice Require that current timestamp is not past order expiration, otherwise cancel the order and continue the loop.
        if (block.timestamp > order.expirationTimestamp) {
            return _cancelSandboxLimitOrderViaExecutor(order);
        }

        ///@notice Check that the account has enough gas credits to refresh the order, otherwise, cancel the order and continue the loop.
        if (executionCreditBalance < REFRESH_FEE) {
            return _cancelSandboxLimitOrderViaExecutor(order);
        } else {
            if (executionCreditBalance - REFRESH_FEE < minExecutionCredit) {
                return _cancelSandboxLimitOrderViaExecutor(order);
            }
        }

        if (
            IERC20(order.tokenIn).balanceOf(order.owner) <
            order.amountInRemaining
        ) {
            return _cancelSandboxLimitOrderViaExecutor(order);
        }

        ///@notice If the time elapsed since the last refresh is less than 30 days, continue to the next iteration in the loop.
        if (block.timestamp - order.lastRefreshTimestamp < REFRESH_INTERVAL) {
            revert OrderNotEligibleForRefresh(order.orderId);
        }

        orderIdToSandboxLimitOrder[order.orderId].executionCreditRemaining =
            executionCreditBalance -
            uint128(REFRESH_FEE);
        emit OrderExecutionCreditUpdated(
            order.orderId,
            executionCreditBalance - REFRESH_FEE
        );
        ///@notice update the order's last refresh timestamp
        ///@dev uint32(block.timestamp).
        orderIdToSandboxLimitOrder[order.orderId].lastRefreshTimestamp = uint32(
            block.timestamp
        );

        ///@notice Emit an event to notify the off-chain executors that the order has been refreshed.
        emit OrderRefreshed(
            order.orderId,
            order.lastRefreshTimestamp,
            order.expirationTimestamp
        );

        return REFRESH_FEE;
    }

    //===========================================================================
    //==================== Sandbox Execution Functions ==========================
    //===========================================================================

    ///@notice
    /* This function caches the state of the specified orders before and after arbitrary execution, ensuring that the proper
    prices and fill amounts have been satisfied.
     */

    ///@param sandboxMulticall -
    function executeOrdersViaSandboxMulticall(
        SandboxLimitOrderRouter.SandboxMulticall calldata sandboxMulticall
    ) external onlySandboxLimitOrderRouter nonReentrant {
        ///@notice Initialize arrays to hold pre execution validation state.
        PreSandboxExecutionState
            memory preSandboxExecutionState = _initializePreSandboxExecutionState(
                sandboxMulticall.orderIdBundles,
                sandboxMulticall.fillAmounts
            );

        ///@notice Call the limit order executor to transfer all of the order owners tokens to the contract.
        IConveyorExecutor(LIMIT_ORDER_EXECUTOR).executeSandboxLimitOrders(
            preSandboxExecutionState.sandboxLimitOrders,
            sandboxMulticall
        );

        ///@notice Post execution, assert that all of the order owners have received >= their exact amount out
        uint256 executionGasCompensation = _validateSandboxExecutionAndFillOrders(
                sandboxMulticall.orderIdBundles,
                sandboxMulticall.fillAmounts,
                preSandboxExecutionState
            );

        _safeTransferETH(tx.origin, executionGasCompensation);
    }

    ///@notice Function to initialize the PreSandboxExecution state prior to sandbox execution.
    ///@param orderIdBundles - The order ids to execute.
    ///@param fillAmounts - The fill amounts for each order.
    ///@return preSandboxExecutionState - The PreSandboxExecution state.
    function _initializePreSandboxExecutionState(
        bytes32[][] calldata orderIdBundles,
        uint128[] calldata fillAmounts
    )
        internal
        view
        returns (PreSandboxExecutionState memory preSandboxExecutionState)
    {
        ///@notice Initialize data to hold pre execution validation state.
        preSandboxExecutionState.sandboxLimitOrders = new SandboxLimitOrder[](
            fillAmounts.length
        );
        preSandboxExecutionState.orderOwners = new address[](
            fillAmounts.length
        );
        preSandboxExecutionState.initialTokenInBalances = new uint256[](
            fillAmounts.length
        );
        preSandboxExecutionState.initialTokenOutBalances = new uint256[](
            fillAmounts.length
        );

        uint256 arrayIndex = 0;
        {
            for (uint256 i = 0; i < orderIdBundles.length; ) {
                bytes32[] memory orderIdBundle = orderIdBundles[i];

                for (uint256 j = 0; j < orderIdBundle.length; ) {
                    bytes32 orderId = orderIdBundle[j];

                    ///@notice Transfer the tokens from the order owners to the sandbox router contract.
                    ///@dev This function is executed in the context of ConveyorExecutor as a delegatecall.

                    ///@notice Get the current order
                    SandboxLimitOrder
                        memory currentOrder = orderIdToSandboxLimitOrder[
                            orderId
                        ];

                    if (currentOrder.orderId == bytes32(0)) {
                        revert OrderDoesNotExist(orderId);
                    }

                    preSandboxExecutionState.orderOwners[
                        arrayIndex
                    ] = currentOrder.owner;

                    preSandboxExecutionState.sandboxLimitOrders[
                        arrayIndex
                    ] = currentOrder;

                    ///@notice Cache amountSpecifiedToFill for intermediate calculations
                    uint128 amountSpecifiedToFill = fillAmounts[arrayIndex];
                    ///@notice Require the amountSpecifiedToFill is less than or equal to the amountInRemaining of the order.
                    if (
                        amountSpecifiedToFill > currentOrder.amountInRemaining
                    ) {
                        revert FillAmountSpecifiedGreaterThanAmountRemaining(
                            amountSpecifiedToFill,
                            currentOrder.amountInRemaining,
                            currentOrder.orderId
                        );
                    }

                    ///@notice Cache the the pre execution state of the order details
                    preSandboxExecutionState.initialTokenInBalances[
                        arrayIndex
                    ] = IERC20(currentOrder.tokenIn).balanceOf(
                        currentOrder.owner
                    );

                    preSandboxExecutionState.initialTokenOutBalances[
                        arrayIndex
                    ] = IERC20(currentOrder.tokenOut).balanceOf(
                        currentOrder.owner
                    );

                    unchecked {
                        ++arrayIndex;
                    }

                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    ///@notice Function to validate the execution state of the orders and fill the orders
    ///@param orderIdBundles - The order ids being executed.
    ///@param fillAmounts - The fill amounts for each order.
    ///@param preSandboxExecutionState - The pre execution state of the orders.
    function _validateSandboxExecutionAndFillOrders(
        bytes32[][] calldata orderIdBundles,
        uint128[] calldata fillAmounts,
        PreSandboxExecutionState memory preSandboxExecutionState
    ) internal returns (uint256 cumulativeExecutionCreditCompensation) {
        ///@notice Initialize the orderIdIndex to 0.
        ///@dev orderIdIndex is used to track the current index of the sandboxLimitOrders array in the preSandboxExecutionState.
        uint256 orderIdIndex = 0;
        ///@notice Iterate through each bundle in the order id bundles.
        for (uint256 i = 0; i < orderIdBundles.length; ) {
            bytes32[] memory orderIdBundle = orderIdBundles[i];
            ///@notice If the bundle length is greater than 1, then the validate a multi-order bundle.
            if (orderIdBundle.length > 1) {
                cumulativeExecutionCreditCompensation += _validateMultiOrderBundle(
                    orderIdIndex,
                    orderIdBundle.length,
                    fillAmounts,
                    preSandboxExecutionState
                );
                ///@notice Increment the orderIdIndex by the length of the bundle.
                orderIdIndex += orderIdBundle.length - 1;
                ///@notice Else validate a single order bundle.
            } else {
                cumulativeExecutionCreditCompensation += _validateSingleOrderBundle(
                    preSandboxExecutionState.sandboxLimitOrders[orderIdIndex],
                    fillAmounts[orderIdIndex],
                    preSandboxExecutionState.initialTokenInBalances[
                        orderIdIndex
                    ],
                    preSandboxExecutionState.initialTokenOutBalances[
                        orderIdIndex
                    ]
                );
                ///@notice Increment the orderIdIndex by 1.
                ++orderIdIndex;
            }

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Function to validate a single order bundle.
    ///@param currentOrder - The current order to be validated.
    ///@param fillAmount - The fill amount for the current order.
    ///@param initialTokenInBalance - The initial token in balance of the order owner.
    ///@param initialTokenOutBalance - The initial token out balance of the order owner.
    function _validateSingleOrderBundle(
        SandboxLimitOrder memory currentOrder,
        uint128 fillAmount,
        uint256 initialTokenInBalance,
        uint256 initialTokenOutBalance
    ) internal returns (uint256 executionCompensation) {
        ///@notice Cache values for post execution assertions
        uint128 amountOutRequired = uint128(
            ConveyorMath.mul64U(
                ConveyorMath.divUU(
                    currentOrder.amountOutRemaining,
                    currentOrder.amountInRemaining
                ),
                fillAmount
            )
        );
        ///@notice If amountOutRemaining/amountInRemaining rounds to 0 revert the tx.
        if (amountOutRequired == 0) {
            revert AmountOutRequiredIsZero(currentOrder.orderId);
        }
        ///@notice Get the current tokenIn/Out balances of the order owner.
        uint256 currentTokenInBalance = IERC20(currentOrder.tokenIn).balanceOf(
            currentOrder.owner
        );

        uint256 currentTokenOutBalance = IERC20(currentOrder.tokenOut)
            .balanceOf(currentOrder.owner);

        ///@notice Assert that the tokenIn balance is decremented by the fill amount exactly
        if (initialTokenInBalance - currentTokenInBalance > fillAmount) {
            revert SandboxFillAmountNotSatisfied(
                currentOrder.orderId,
                initialTokenInBalance - currentTokenInBalance,
                fillAmount
            );
        }

        ///@notice Assert that the tokenOut balance is greater than or equal to the amountOutRequired
        if (
            currentTokenOutBalance - initialTokenOutBalance != amountOutRequired
        ) {
            revert SandboxAmountOutRequiredNotSatisfied(
                currentOrder.orderId,
                currentTokenOutBalance - initialTokenOutBalance,
                amountOutRequired
            );
        }

        ///@notice Update the sandboxLimitOrder after the execution requirements have been met.
        if (currentOrder.amountInRemaining == fillAmount) {
            _resolveCompletedOrder(currentOrder.orderId);
            executionCompensation = currentOrder.executionCreditRemaining;
        } else {
            ///@notice Update the state of the order to parial filled quantities.
            executionCompensation = _partialFillSandboxLimitOrder(
                uint128(initialTokenInBalance - currentTokenInBalance),
                uint128(currentTokenOutBalance - initialTokenOutBalance),
                currentOrder.orderId
            );
        }
    }

    ///@notice Function to validate a multi order bundle.
    ///@param orderIdIndex - The index of the current order in the preSandboxExecutionState.
    ///@param bundleLength - The length of the bundle.
    ///@param fillAmounts - The fill amounts for each order in the bundle.
    ///@param preSandboxExecutionState - The pre execution state of the orders.
    function _validateMultiOrderBundle(
        uint256 orderIdIndex,
        uint256 bundleLength,
        uint128[] memory fillAmounts,
        PreSandboxExecutionState memory preSandboxExecutionState
    ) internal returns (uint256 cumulativeExecutionCompensation) {
        ///@notice Cache the first order in the bundle
        SandboxLimitOrder memory prevOrder = preSandboxExecutionState
            .sandboxLimitOrders[orderIdIndex];

        ///@notice Cacluate the amountOut required for the first order in the bundle
        uint128 amountOutRequired = uint128(
            ConveyorMath.mul64U(
                ConveyorMath.divUU(
                    prevOrder.amountOutRemaining,
                    prevOrder.amountInRemaining
                ),
                fillAmounts[orderIdIndex]
            )
        );

        if (amountOutRequired == 0) {
            revert AmountOutRequiredIsZero(prevOrder.orderId);
        }

        ///@notice Update the cumulative fill amount to include the fill amount for the first order in the bundle
        uint256 cumulativeFillAmount = fillAmounts[orderIdIndex];
        ///@notice Update the cumulativeAmountOutRequired to include the amount out required for the first order in the bundle
        uint256 cumulativeAmountOutRequired = amountOutRequired;
        ///@notice Set the orderOwner to the first order in the bundle
        address orderOwner = prevOrder.owner;
        ///@notice Update the offset for the sandboxLimitOrders array to correspond with the order in the bundle
        uint256 offset = orderIdIndex;

        {
            ///@notice For each order in the bundle
            for (uint256 i = 1; i < bundleLength; ) {
                ///@notice Cache the order
                SandboxLimitOrder memory currentOrder = preSandboxExecutionState
                    .sandboxLimitOrders[offset + 1];

                ///@notice Cache the tokenIn and tokenOut balance for the current order
                uint256 currentTokenInBalance = IERC20(prevOrder.tokenIn)
                    .balanceOf(orderOwner);

                uint256 currentTokenOutBalance = IERC20(prevOrder.tokenOut)
                    .balanceOf(orderOwner);

                ///@notice Cache the amountOutRequired for the current order
                amountOutRequired = uint128(
                    ConveyorMath.mul64U(
                        ConveyorMath.divUU(
                            currentOrder.amountOutRemaining,
                            currentOrder.amountInRemaining
                        ),
                        fillAmounts[offset + 1]
                    )
                );

                if (amountOutRequired == 0) {
                    revert AmountOutRequiredIsZero(currentOrder.orderId);
                }

                ///@notice If the current order and previous order tokenIn do not match, assert that the cumulative fill amount can be met.
                if (currentOrder.tokenIn != prevOrder.tokenIn) {
                    ///@notice Assert that the tokenIn balance is decremented by the fill amount exactly.
                    if (
                        preSandboxExecutionState.initialTokenInBalances[
                            offset
                        ] -
                            currentTokenInBalance >
                        cumulativeFillAmount
                    ) {
                        revert SandboxFillAmountNotSatisfied(
                            prevOrder.orderId,
                            preSandboxExecutionState.initialTokenInBalances[
                                offset
                            ] - currentTokenInBalance,
                            cumulativeFillAmount
                        );
                    }
                    ///@notice Reset the cumulative fill amount to the fill amount for the current order.
                    cumulativeFillAmount = fillAmounts[offset + 1];
                } else {
                    ///@notice Update the cumulative fill amount to include the fill amount for the current order.
                    cumulativeFillAmount += fillAmounts[offset + 1];
                }

                if (currentOrder.tokenOut != prevOrder.tokenOut) {
                    ///@notice Assert that the tokenOut balance is greater than or equal to the amountOutRequired.
                    if (
                        currentTokenOutBalance -
                            preSandboxExecutionState.initialTokenOutBalances[
                                offset
                            ] !=
                        cumulativeAmountOutRequired
                    ) {
                        revert SandboxAmountOutRequiredNotSatisfied(
                            prevOrder.orderId,
                            currentTokenOutBalance -
                                preSandboxExecutionState
                                    .initialTokenOutBalances[offset],
                            cumulativeAmountOutRequired
                        );
                    }
                    ///@notice Reset the cumulativeAmountOutRequired to the amountOutRequired for the current order.
                    cumulativeAmountOutRequired = amountOutRequired;
                } else {
                    ///@notice Update the cumulativeAmountOutRequired to include the amountOutRequired for the current order.
                    cumulativeAmountOutRequired += amountOutRequired;
                }
                _resolveOrPartialFillOrder(
                    prevOrder,
                    offset,
                    fillAmounts,
                    cumulativeExecutionCompensation
                );
                ///@notice Set prevOrder to the currentOrder and increment the offset.
                prevOrder = currentOrder;
                ++offset;

                unchecked {
                    ++i;
                }
            }
            _resolveOrPartialFillOrder(
                prevOrder,
                offset - 1,
                fillAmounts,
                cumulativeExecutionCompensation
            );
        }
    }

    function _resolveOrPartialFillOrder(
        SandboxLimitOrder memory prevOrder,
        uint256 offset,
        uint128[] memory fillAmounts,
        uint256 cumulativeExecutionCompensation
    ) internal returns (uint256) {
        ///@notice Update the sandboxLimitOrder after the execution requirements have been met.
        if (prevOrder.amountInRemaining == fillAmounts[offset]) {
            _resolveCompletedOrder(prevOrder.orderId);
            cumulativeExecutionCompensation += prevOrder
                .executionCreditRemaining;
        } else {
            ///@notice Update the state of the order to parial filled quantities.
            cumulativeExecutionCompensation += _partialFillSandboxLimitOrder(
                uint128(fillAmounts[offset]),
                uint128(
                    ConveyorMath.mul64U(
                        ConveyorMath.divUU(
                            prevOrder.amountOutRemaining,
                            prevOrder.amountInRemaining
                        ),
                        fillAmounts[offset]
                    )
                ),
                prevOrder.orderId
            );
        }

        return cumulativeExecutionCompensation;
    }

    //===========================================================================
    //====================== Internal Helper Functions ==========================
    //===========================================================================

    ///@notice Internal function to partially fill a sandbox limit order and update the remaining quantity.
    ///@param amountInFilled - The amount in that was filled for the order.
    ///@param amountOutFilled - The amount out that was filled for the order.
    ///@param orderId - The orderId of the order that was filled.
    function _partialFillSandboxLimitOrder(
        uint128 amountInFilled,
        uint128 amountOutFilled,
        bytes32 orderId
    ) internal returns (uint256) {
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];
        uint128 executionCreditRemaining = order.executionCreditRemaining;
        ///@notice Decrement totalOrdersQuantity on order.tokenIn for order owner
        decrementTotalOrdersQuantity(
            order.tokenIn,
            order.owner,
            amountInFilled
        );

        ///@notice Cache the Orders amountInRemaining.
        uint128 amountInRemaining = order.amountInRemaining;
        ///@notice Cache the Orders feeRemaining.
        uint128 feeRemaining = order.feeRemaining;
        uint128 percentFilled = order.fillPercent != 0
            ? ConveyorMath.mul64x64(
                order.fillPercent,
                ConveyorMath.divUU(amountInFilled, amountInRemaining)
            )
            : ConveyorMath.divUU(amountInFilled, amountInRemaining);
        ///@notice Update the orders fillPercent to amountInFilled/amountInRemaining as 16.16 fixed point
        orderIdToSandboxLimitOrder[orderId].fillPercent += percentFilled;

        ///@notice Update the orders amountInRemaining to amountInRemaining - amountInFilled.
        orderIdToSandboxLimitOrder[orderId].amountInRemaining =
            order.amountInRemaining -
            amountInFilled;
        ///@notice Update the orders amountOutRemaining to amountOutRemaining - amountOutFilled.
        orderIdToSandboxLimitOrder[orderId].amountOutRemaining =
            order.amountOutRemaining -
            amountOutFilled;

        ///@notice Update the status of the order to PartialFilled
        addressToOrderIds[order.owner][order.orderId] = OrderType
            .PartialFilledSandboxLimitOrder;

        uint128 updatedFeeRemaining = feeRemaining -
            uint128(
                ConveyorMath.mul64U(
                    ConveyorMath.divUU(amountInFilled, amountInRemaining),
                    feeRemaining
                )
            );

        ///@notice Update the orders feeRemaining to feeRemaining - feeRemaining * amountInFilled/amountInRemaining.
        orderIdToSandboxLimitOrder[orderId].feeRemaining = updatedFeeRemaining;

        uint128 executionCreditCompensation = uint128(
            ConveyorMath.mul64U(percentFilled, executionCreditRemaining)
        );

        uint128 updatedExecutionCreditRemaining = executionCreditRemaining -
            executionCreditCompensation;

        ///@notice Decrement the execution credit by the proportion of the fillAmount/amountInRemaining(at placement time)
        orderIdToSandboxLimitOrder[order.orderId]
            .executionCreditRemaining = updatedExecutionCreditRemaining;

        emit OrderPartialFilled(
            order.orderId,
            order.amountInRemaining - amountInFilled,
            order.amountOutRemaining - amountOutFilled,
            updatedExecutionCreditRemaining,
            updatedFeeRemaining
        );

        return executionCreditCompensation;
    }

    ///@notice Function to remove an order from the system.
    ///@param orderId - The orderId that should be removed from the system.
    function _removeOrderFromSystem(bytes32 orderId) internal {
        ///@dev the None order type can not reach here so we can use `else`
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];

        ///@notice Remove the order from the system
        delete orderIdToSandboxLimitOrder[order.orderId];

        ///@notice Decrement from total orders per address
        --totalOrdersPerAddress[order.owner];

        ///@notice Decrement totalOrdersQuantity on order.tokenIn for order owner
        decrementTotalOrdersQuantity(
            order.tokenIn,
            order.owner,
            order.amountInRemaining
        );
    }

    ///@notice Function to resolve an order as completed.
    ///@param orderId - The orderId that should be resolved from the system.
    function _resolveCompletedOrder(bytes32 orderId) internal {
        ///@dev the None order type can not reach here so we can use `else`

        ///@notice Grab the order currently in the state of the contract based on the orderId of the order passed.
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];

        ///@notice If the order has already been removed from the contract revert.
        if (order.orderId == bytes32(0)) {
            revert DuplicateOrderIdsInOrderGroup();
        }
        ///@notice Remove the order from the system
        delete orderIdToSandboxLimitOrder[orderId];
        delete addressToOrderIds[order.owner][orderId];

        ///@notice Decrement from total orders per address
        --totalOrdersPerAddress[order.owner];

        ///@notice Decrement totalOrdersQuantity on order.tokenIn for order owner
        decrementTotalOrdersQuantity(
            order.tokenIn,
            order.owner,
            order.amountInRemaining
        );

        ///@notice Update the status of the order to filled
        addressToOrderIds[order.owner][order.orderId] = OrderType
            .FilledSandboxLimitOrder;

        ///@notice Emit the event that the order has been filled.
        bytes32[] memory filledOrderIds = new bytes32[](1);
        filledOrderIds[0] = order.orderId;

        emit OrderFilled(filledOrderIds);
    }

    ///@notice Decrement an owner's total order value on a specific token.
    ///@param token - Token address to decrement the total order value on.
    ///@param orderOwner - Account address to decrement the total order value from.
    ///@param quantity - Amount to decrement the total order value by.
    function decrementTotalOrdersQuantity(
        address token,
        address orderOwner,
        uint256 quantity
    ) internal {
        bytes32 totalOrdersValueKey = keccak256(abi.encode(orderOwner, token));
        totalOrdersQuantity[totalOrdersValueKey] -= quantity;
    }

    ///@notice Update an owner's total order value on a specific token.
    ///@param token - Token address to update the total order value on.
    ///@param orderOwner - Account address to update the total order value from.
    ///@param newQuantity - Amount set the the new total order value to.
    function _updateTotalOrdersQuantity(
        address token,
        address orderOwner,
        uint256 newQuantity
    ) internal {
        bytes32 totalOrdersValueKey = keccak256(abi.encode(orderOwner, token));
        totalOrdersQuantity[totalOrdersValueKey] = newQuantity;
    }

    ///@notice Transfer ETH to a specific address and require that the call was successful.
    ///@param to - The address that should be sent Ether.
    ///@param amount - The amount of Ether that should be sent.
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    //===========================================================================
    //======================== Public View Functions ============================
    //===========================================================================

    /// @notice Helper function to get the total order value on a specific token for the msg.sender.
    /// @param token - Token address to get total order value on.
    /// @return totalOrderValue - The total value of orders that exist for the msg.sender on the specified token.
    function getTotalOrdersValue(address token)
        public
        view
        returns (uint256 totalOrderValue)
    {
        bytes32 totalOrdersValueKey = keccak256(abi.encode(msg.sender, token));
        return totalOrdersQuantity[totalOrdersValueKey];
    }

    function getAllOrderIdsLength(address orderOwner)
        public
        view
        returns (uint256)
    {
        return addressToAllOrderIds[orderOwner].length;
    }

    function getSandboxLimitOrderRouterAddress() public view returns (address) {
        return SANDBOX_LIMIT_ORDER_ROUTER;
    }

    function getSandboxLimitOrderById(bytes32 orderId)
        public
        view
        returns (SandboxLimitOrder memory)
    {
        SandboxLimitOrder memory order = orderIdToSandboxLimitOrder[orderId];
        if (order.orderId == bytes32(0)) {
            revert OrderDoesNotExist(orderId);
        }

        return order;
    }

    ///@notice Get all of the order Ids matching the targetOrderType for a given address
    ///@param orderOwner - Target address to get all order Ids for.
    ///@param targetOrderType - Target orderType to retrieve from all orderIds.
    ///@param orderOffset - The first order to start from when checking orderstatus. For example, if order offset is 2, the function will start checking orderId status from the second order.
    ///@param length - The amount of orders to check order status for.
    ///@return - Array of orderIds matching the targetOrderType
    function getOrderIds(
        address orderOwner,
        OrderType targetOrderType,
        uint256 orderOffset,
        uint256 length
    ) public view returns (bytes32[] memory) {
        bytes32[] memory allOrderIds = addressToAllOrderIds[orderOwner];

        uint256 orderIdIndex = 0;
        bytes32[] memory orderIds = new bytes32[](allOrderIds.length);

        uint256 orderOffsetSlot;
        assembly {
            //Adjust the offset slot to be the beginning of the allOrderIds array + 0x20 to get the first order + the order Offset * the size of each order
            orderOffsetSlot := add(
                add(allOrderIds, 0x20),
                mul(orderOffset, 0x20)
            )
        }

        for (uint256 i = 0; i < length; ) {
            bytes32 orderId;
            assembly {
                //Get the orderId at the orderOffsetSlot
                orderId := mload(orderOffsetSlot)
                //Update the orderOffsetSlot
                orderOffsetSlot := add(orderOffsetSlot, 0x20)
            }

            OrderType orderType = addressToOrderIds[orderOwner][orderId];

            if (orderType == targetOrderType) {
                orderIds[orderIdIndex] = orderId;
                ++orderIdIndex;
            }

            unchecked {
                ++i;
            }
        }

        //Reassign length of each array
        assembly {
            mstore(orderIds, orderIdIndex)
        }

        return orderIds;
    }

    function setMinExecutionCredit(uint256 newMinExecutionCredit)
        external
        onlyOwner
    {
        uint256 oldMinExecutionCredit = minExecutionCredit;
        minExecutionCredit = newMinExecutionCredit;
        emit MinExecutionCreditUpdated(
            newMinExecutionCredit,
            oldMinExecutionCredit
        );
    }

    ///@notice Function to confirm ownership transfer of the contract.
    function confirmTransferOwnership() external {
        if (msg.sender != tempOwner) {
            revert MsgSenderIsNotTempOwner();
        }
        owner = msg.sender;
        tempOwner = address(0);
    }

    ///@notice Function to transfer ownership of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }
        tempOwner = newOwner;
    }
}