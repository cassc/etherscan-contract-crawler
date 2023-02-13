// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./LimitOrderSwapRouter.sol";
import "./interfaces/ILimitOrderQuoter.sol";
import "./lib/ConveyorFeeMath.sol";
import "./LimitOrderRouter.sol";
import "./interfaces/ILimitOrderSwapRouter.sol";
import "./interfaces/ISandboxLimitOrderRouter.sol";
import "./interfaces/ISandboxLimitOrderBook.sol";
import "./interfaces/ILimitOrderBook.sol";
import "./interfaces/IConveyorExecutor.sol";

/// @title ConveyorExecutor
/// @author 0xOsiris, 0xKitsune, Conveyor Labs
/// @notice This contract handles all order execution.
contract ConveyorExecutor is IConveyorExecutor, LimitOrderSwapRouter {
    using SafeERC20 for IERC20;
    ///====================================Immutable Storage Variables==============================================//
    address immutable WETH;
    address immutable USDC;
    address immutable LIMIT_ORDER_QUOTER;
    address public immutable LIMIT_ORDER_ROUTER;
    address public immutable SANDBOX_LIMIT_ORDER_BOOK;
    address public immutable SANDBOX_LIMIT_ORDER_ROUTER;

    ///====================================Constants==============================================//

    ///@notice The Maximum Reward a beacon can receive from stoploss execution.
    ///Note:
    /*
     * The maximum reward a beacon can receive from stoploss execution is 0.05 ETH for stoploss orders as a preventative measure for artificial price manipulation.
     */
    uint128 private constant STOP_LOSS_MAX_BEACON_REWARD = 50000000000000000;

    //----------------------Modifiers------------------------------------//

    ///@notice Modifier to restrict smart contracts from calling a function.
    modifier onlyLimitOrderRouter() {
        if (msg.sender != LIMIT_ORDER_ROUTER) {
            revert MsgSenderIsNotLimitOrderRouter();
        }
        _;
    }

    ///@notice Modifier to restrict smart contracts from calling a function.
    modifier onlyOrderBook() {
        if (
            msg.sender != LIMIT_ORDER_ROUTER &&
            msg.sender != SANDBOX_LIMIT_ORDER_BOOK
        ) {
            revert MsgSenderIsNotOrderBook();
        }
        _;
    }

    ///@notice Modifier to restrict smart contracts from calling a function.
    modifier onlySandboxLimitOrderBook() {
        if (msg.sender != SANDBOX_LIMIT_ORDER_BOOK) {
            revert MsgSenderIsNotLimitOrderBook();
        }
        _;
    }

    ///@notice Reentrancy guard modifier.
    modifier nonReentrant() {
        if (reentrancyStatus) {
            revert Reentrancy();
        }

        reentrancyStatus = true;
        _;
        reentrancyStatus = false;
    }

    ///@notice Modifier function to only allow the owner of the contract to call specific functions
    ///@dev Functions with onlyOwner: withdrawConveyorFees, transferOwnership.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert MsgSenderIsNotOwner();
        }

        _;
    }

    ///@notice Temporary owner storage variable when transferring ownership of the contract.
    address tempOwner;

    ///@notice The owner of the Order Router contract
    ///@dev The contract owner can remove the owner funds from the contract, and transfer ownership of the contract.
    address owner;

    ///@notice Conveyor funds balance in the contract.
    uint256 conveyorBalance;

    ///@notice Boolean responsible for indicating if a function has been entered when the nonReentrant modifier is used.
    bool reentrancyStatus = false;

    ///@notice Mapping of addresses to their last checkin time.
    mapping(address => uint256) public lastCheckIn;

    ///====================================Events==============================================//
    /**@notice Event that is emitted when an offchain execution checks into the contract
     */
    event ExecutorCheckIn(address executor, uint256 timestamp);

    ///@param _weth The wrapped native token on the chain.
    ///@param _usdc Pegged stable token on the chain.
    ///@param _limitOrderQuoterAddress The address of the LimitOrderQuoter contract.
    ///@param _dexFactories The Dex factory addresses.
    ///@param _isUniV2 Array of booleans indication whether the Dex is V2 architecture.
    constructor(
        address _weth,
        address _usdc,
        address _limitOrderQuoterAddress,
        address[] memory _dexFactories,
        bool[] memory _isUniV2,
        uint256 _minExecutionCredit
    ) LimitOrderSwapRouter(_dexFactories, _isUniV2) {
        require(_weth != address(0), "Invalid weth address");
        require(_usdc != address(0), "Invalid usdc address");
        require(
            _limitOrderQuoterAddress != address(0),
            "Invalid LimitOrderQuoter address"
        );

        USDC = _usdc;
        WETH = _weth;
        LIMIT_ORDER_QUOTER = _limitOrderQuoterAddress;

        SANDBOX_LIMIT_ORDER_BOOK = address(
            new SandboxLimitOrderBook(
                address(this),
                _weth,
                _usdc,
                _minExecutionCredit
            )
        );

        ///@notice Assign the SANDBOX_LIMIT_ORDER_ROUTER address
        SANDBOX_LIMIT_ORDER_ROUTER = ISandboxLimitOrderBook(
            SANDBOX_LIMIT_ORDER_BOOK
        ).getSandboxLimitOrderRouterAddress();

        LIMIT_ORDER_ROUTER = address(
            new LimitOrderRouter(
                _weth,
                _usdc,
                address(this),
                _minExecutionCredit
            )
        );

        ///@notice assign the owner address
        owner = msg.sender;
    }

    ///@notice Function to monitor Executor checkin.
    function checkIn() external {
        ///@notice Set the lastCheckIn time to the current block timestamp.
        lastCheckIn[msg.sender] = block.timestamp;
        emit ExecutorCheckIn(msg.sender, block.timestamp);
    }

    ///@notice Function to execute a batch of Token to Weth Orders.
    ///@param orders The orders to be executed.
    function executeTokenToWethOrders(
        LimitOrderBook.LimitOrder[] calldata orders
    ) external onlyLimitOrderRouter returns (uint256, uint256) {
        ///@notice Get all of the execution prices on TokenIn to Weth for each dex.
        ///@notice Get all prices for the pairing
        (
            SpotReserve[] memory spotReserveAToWeth,
            address[] memory lpAddressesAToWeth
        ) = getAllPrices(orders[0].tokenIn, WETH, orders[0].feeIn);

        ///@notice Initialize all execution prices for the token pair.
        TokenToWethExecutionPrice[] memory executionPrices = ILimitOrderQuoter(
            LIMIT_ORDER_QUOTER
        ).initializeTokenToWethExecutionPrices(
                spotReserveAToWeth,
                lpAddressesAToWeth
            );

        ///@notice Set totalBeaconReward to 0
        uint256 totalBeaconReward = 0;

        ///@notice Set totalConveyorReward to 0

        uint256 totalConveyorReward = 0;

        for (uint256 i = 0; i < orders.length; ) {
            ///@notice Create a variable to track the best execution price in the array of execution prices.
            uint256 bestPriceIndex = ILimitOrderQuoter(LIMIT_ORDER_QUOTER)
                .findBestTokenToWethExecutionPrice(
                    executionPrices,
                    orders[i].buy
                );

            {
                ///@notice Pass the order, maxBeaconReward, and TokenToWethExecutionPrice into _executeTokenToWethSingle for execution.
                (
                    uint256 conveyorReward,
                    uint256 beaconReward
                ) = _executeTokenToWethOrder(
                        orders[i],
                        executionPrices[bestPriceIndex]
                    );
                ///@notice Increment the total beacon and conveyor reward.
                totalBeaconReward += beaconReward;
                totalConveyorReward += conveyorReward;
            }

            ///@notice Update the best execution price.
            executionPrices[bestPriceIndex] = ILimitOrderQuoter(
                LIMIT_ORDER_QUOTER
            ).simulateTokenToWethPriceChange(
                    uint128(orders[i].quantity),
                    executionPrices[bestPriceIndex]
                );

            unchecked {
                ++i;
            }
        }
        ///@notice Transfer the totalBeaconReward to the off chain executor.
        _transferBeaconReward(totalBeaconReward, tx.origin, WETH);

        ///@notice Increment the conveyor balance.
        conveyorBalance += totalConveyorReward;

        return (totalBeaconReward, totalConveyorReward);
    }

    ///@notice Function to execute a single Token To Weth order.
    ///@param order - The order to be executed.
    ///@param executionPrice - The best priced TokenToWethExecutionPrice to execute the order on.
    function _executeTokenToWethOrder(
        LimitOrderBook.LimitOrder calldata order,
        LimitOrderSwapRouter.TokenToWethExecutionPrice memory executionPrice
    ) internal returns (uint256, uint256) {
        ///@notice Swap the batch amountIn on the batch lp address and send the weth back to the contract.
        (
            uint128 amountOutWeth,
            uint128 conveyorReward,
            uint128 beaconReward
        ) = _executeSwapTokenToWethOrder(
                executionPrice.lpAddressAToWeth,
                order
            );

        ///@notice Transfer the tokenOut amount to the order owner.
        _transferTokensOutToOwner(order.owner, amountOutWeth, WETH);

        return (uint256(conveyorReward), uint256(beaconReward));
    }

    ///@notice Function to execute a swap from TokenToWeth for an order.
    ///@param lpAddressAToWeth - The best priced TokenToTokenExecutionPrice for the order to be executed on.
    ///@param order - The order to be executed.
    ///@return amountOutWeth - The amountOut in Weth after the swap.
    function _executeSwapTokenToWethOrder(
        address lpAddressAToWeth,
        LimitOrderBook.LimitOrder calldata order
    )
        internal
        returns (
            uint128 amountOutWeth,
            uint128 conveyorReward,
            uint128 beaconReward
        )
    {
        ///@notice Cache the order Quantity.
        uint256 orderQuantity = order.quantity;

        uint24 feeIn = order.feeIn;
        address tokenIn = order.tokenIn;

        ///@notice Calculate the amountOutMin for the tokenA to Weth swap.
        uint256 amountOutMinAToWeth = ILimitOrderQuoter(LIMIT_ORDER_QUOTER)
            .calculateAmountOutMinAToWeth(
                lpAddressAToWeth,
                orderQuantity,
                order.taxIn,
                feeIn,
                tokenIn
            );

        ///@notice Swap from tokenA to Weth.
        amountOutWeth = uint128(
            _swap(
                tokenIn,
                WETH,
                lpAddressAToWeth,
                feeIn,
                orderQuantity,
                amountOutMinAToWeth,
                address(this),
                order.owner
            )
        );

        ///@notice Take out fees from the amountOut.
        uint128 protocolFee = calculateFee(amountOutWeth, USDC, WETH);

        ///@notice Calculate the conveyorReward and executor reward.
        (conveyorReward, beaconReward) = ConveyorFeeMath.calculateReward(
            protocolFee,
            amountOutWeth
        );
        ///@notice If the order is a stoploss, and the beaconReward surpasses 0.05 WETH. Cap the protocol and the off chain executor at 0.05 WETH.
        if (order.stoploss) {
            if (STOP_LOSS_MAX_BEACON_REWARD < beaconReward) {
                beaconReward = STOP_LOSS_MAX_BEACON_REWARD;
                conveyorReward = STOP_LOSS_MAX_BEACON_REWARD;
            }
        }

        ///@notice Get the AmountIn for weth to tokenB.
        amountOutWeth = amountOutWeth - (beaconReward + conveyorReward);
    }

    ///@notice Function to execute an array of TokenToToken orders
    ///@param orders - Array of orders to be executed.
    function executeTokenToTokenOrders(
        LimitOrderBook.LimitOrder[] calldata orders
    ) external onlyLimitOrderRouter returns (uint256, uint256) {
        TokenToTokenExecutionPrice[] memory executionPrices;
        address tokenIn = orders[0].tokenIn;

        uint24 feeIn = orders[0].feeIn;
        uint24 feeOut = orders[0].feeOut;

        {
            ///@notice Get all execution prices.
            ///@notice Get all prices for the pairing tokenIn to Weth
            (
                SpotReserve[] memory spotReserveAToWeth,
                address[] memory lpAddressesAToWeth
            ) = getAllPrices(tokenIn, WETH, feeIn);

            ///@notice Get all prices for the pairing Weth to tokenOut
            (
                SpotReserve[] memory spotReserveWethToB,
                address[] memory lpAddressWethToB
            ) = getAllPrices(WETH, orders[0].tokenOut, feeOut);

            executionPrices = ILimitOrderQuoter(LIMIT_ORDER_QUOTER)
                .initializeTokenToTokenExecutionPrices(
                    tokenIn,
                    spotReserveAToWeth,
                    lpAddressesAToWeth,
                    spotReserveWethToB,
                    lpAddressWethToB
                );
        }

        ///@notice Set totalBeaconReward to 0
        uint256 totalBeaconReward = 0;
        ///@notice Set totalConveyorReward to 0
        uint256 totalConveyorReward = 0;

        ///@notice Loop through each Order.
        for (uint256 i = 0; i < orders.length; ) {
            ///@notice Create a variable to track the best execution price in the array of execution prices.
            uint256 bestPriceIndex = ILimitOrderQuoter(LIMIT_ORDER_QUOTER)
                .findBestTokenToTokenExecutionPrice(
                    executionPrices,
                    orders[i].buy
                );

            {
                ///@notice Pass the order, maxBeaconReward, and TokenToWethExecutionPrice into _executeTokenToWethSingle for execution.
                (
                    uint256 conveyorReward,
                    uint256 beaconReward
                ) = _executeTokenToTokenOrder(
                        orders[i],
                        executionPrices[bestPriceIndex]
                    );
                totalBeaconReward += beaconReward;
                totalConveyorReward += conveyorReward;
            }

            ///@notice Update the best execution price.
            executionPrices[bestPriceIndex] = ILimitOrderQuoter(
                LIMIT_ORDER_QUOTER
            ).simulateTokenToTokenPriceChange(
                    uint128(orders[i].quantity),
                    executionPrices[bestPriceIndex]
                );

            unchecked {
                ++i;
            }
        }
        ///@notice Transfer the totalBeaconReward to the off chain executor.
        _transferBeaconReward(totalBeaconReward, tx.origin, WETH);

        conveyorBalance += totalConveyorReward;

        return (totalBeaconReward, totalConveyorReward);
    }

    ///@notice Function to execute a single Token To Token order.
    ///@param order - The order to be executed.
    ///@param executionPrice - The best priced TokenToTokenExecution price to execute the order on.
    function _executeTokenToTokenOrder(
        LimitOrderBook.LimitOrder calldata order,
        TokenToTokenExecutionPrice memory executionPrice
    ) internal returns (uint256, uint256) {
        ///@notice Initialize variables to prevent stack too deep.
        uint256 amountInWethToB;
        uint128 conveyorReward;
        uint128 beaconReward;

        ///@notice Scope to prevent stack too deep.
        {
            ///@notice If the tokenIn is not weth.
            if (order.tokenIn != WETH) {
                ///@notice Execute the first swap from tokenIn to weth.
                (
                    amountInWethToB,
                    conveyorReward,
                    beaconReward
                ) = _executeSwapTokenToWethOrder(
                    executionPrice.lpAddressAToWeth,
                    order
                );

                if (amountInWethToB == 0) {
                    revert InsufficientOutputAmount(0, 1);
                }
            } else {
                ///@notice Transfer the TokenIn to the contract.
                _transferTokensToContract(order);

                ///@notice Cache the order quantity.
                uint256 amountIn = order.quantity;

                ///@notice Take out fees from the batch amountIn since token0 is weth.
                uint128 protocolFee = calculateFee(
                    uint128(amountIn),
                    USDC,
                    WETH
                );

                ///@notice Calculate the conveyorReward and the off-chain logic executor reward.
                (conveyorReward, beaconReward) = ConveyorFeeMath
                    .calculateReward(protocolFee, uint128(amountIn));

                ///@notice If the order is a stoploss, and the beaconReward surpasses 0.05 WETH. Cap the protocol and the off chain executor at 0.05 WETH.
                if (order.stoploss) {
                    if (STOP_LOSS_MAX_BEACON_REWARD < beaconReward) {
                        beaconReward = STOP_LOSS_MAX_BEACON_REWARD;
                        conveyorReward = STOP_LOSS_MAX_BEACON_REWARD;
                    }
                }

                ///@notice Get the amountIn for the Weth to tokenB swap.
                amountInWethToB = amountIn - (beaconReward + conveyorReward);
            }
        }

        ///@notice Swap Weth for tokenB.
        uint256 amountOutInB = _swap(
            WETH,
            order.tokenOut,
            executionPrice.lpAddressWethToB,
            order.feeOut,
            amountInWethToB,
            order.amountOutMin,
            order.owner,
            address(this)
        );

        if (amountOutInB == 0) {
            revert InsufficientOutputAmount(0, 1);
        }

        return (uint256(conveyorReward), uint256(beaconReward));
    }

    ///@notice Transfer the order quantity to the contract.
    ///@param order - The orders tokens to be transferred.
    function _transferTokensToContract(LimitOrderBook.LimitOrder calldata order)
        internal
    {
        IERC20(order.tokenIn).safeTransferFrom(
            order.owner,
            address(this),
            order.quantity
        );
    }

    ///@notice Function to execute multicall orders from the context of ConveyorExecutor.
    ///@param orders The orders to be executed.
    ///@param sandboxMulticall -
    ///@dev
    /*The sandBoxRouter address is an immutable address from the sandboxLimitOrderBook.
    Since the function is onlySandboxLimitOrderBook, the sandBoxRouter address will never change*/
    function executeSandboxLimitOrders(
        SandboxLimitOrderBook.SandboxLimitOrder[] calldata orders,
        SandboxLimitOrderRouter.SandboxMulticall calldata sandboxMulticall
    ) external onlySandboxLimitOrderBook nonReentrant {
        uint256 expectedAccumulatedFees = 0;

        if (sandboxMulticall.transferAddresses.length > 0) {
            ///@notice Ensure that the transfer address array is equal to the length of orders to avoid out of bounds index errors
            if (sandboxMulticall.transferAddresses.length != orders.length) {
                revert InvalidTransferAddressArray();
            }

            ///@notice Iterate through each order and transfer the amountSpecifiedToFill to the multicall execution contract.
            for (uint256 i = 0; i < orders.length; ) {
                uint128 fillAmount = sandboxMulticall.fillAmounts[i];
                IERC20(orders[i].tokenIn).safeTransferFrom(
                    orders[i].owner,
                    sandboxMulticall.transferAddresses[i],
                    fillAmount
                );

                uint256 feeRequired = ConveyorMath.mul64U(
                    ConveyorMath.divUU(fillAmount, orders[i].amountInRemaining),
                    orders[i].feeRemaining
                );

                if (feeRequired == 0) {
                    revert InsufficientFillAmountSpecified(
                        fillAmount,
                        orders[i].amountInRemaining
                    );
                }
                expectedAccumulatedFees += feeRequired;

                unchecked {
                    ++i;
                }
            }
        } else {
            ///@notice Iterate through each order and transfer the amountSpecifiedToFill to the multicall execution contract.
            for (uint256 i = 0; i < orders.length; ) {
                uint128 fillAmount = sandboxMulticall.fillAmounts[i];
                IERC20(orders[i].tokenIn).safeTransferFrom(
                    orders[i].owner,
                    SANDBOX_LIMIT_ORDER_ROUTER,
                    fillAmount
                );
                uint256 feeRequired = ConveyorMath.mul64U(
                    ConveyorMath.divUU(fillAmount, orders[i].amountInRemaining),
                    orders[i].feeRemaining
                );

                if (feeRequired == 0) {
                    revert InsufficientFillAmountSpecified(
                        fillAmount,
                        orders[i].amountInRemaining
                    );
                }
                expectedAccumulatedFees += feeRequired;

                unchecked {
                    ++i;
                }
            }
        }

        ///@notice Cache the contract balance to check if the fee was paid post execution
        uint256 contractBalancePreExecution = IERC20(WETH).balanceOf(
            address(this)
        );

        ///@notice acll the SandboxRouter callback to execute the calldata from the sandboxMulticall
        ISandboxLimitOrderRouter(SANDBOX_LIMIT_ORDER_ROUTER)
            .sandboxRouterCallback(sandboxMulticall);

        _requireConveyorFeeIsPaid(
            contractBalancePreExecution,
            expectedAccumulatedFees
        );
    }

    ///@notice Helper function to assert Protocol fees have been paid during sandbox execution.
    ///@param contractBalancePreExecution - The contract balance before execution in WETH.
    ///@param expectedAccumulatedFees - The expected accumulated fees in WETH.
    function _requireConveyorFeeIsPaid(
        uint256 contractBalancePreExecution,
        uint256 expectedAccumulatedFees
    ) internal view {
        ///@notice Check if the contract balance is greater than or equal to the contractBalancePreExecution + expectedAccumulatedFees
        uint256 contractBalancePostExecution = IERC20(WETH).balanceOf(
            address(this)
        );

        bool feeIsPaid;
        assembly {
            feeIsPaid := iszero(
                lt(
                    contractBalancePostExecution,
                    add(contractBalancePreExecution, expectedAccumulatedFees)
                )
            )
        }

        ///@notice If the fees are not paid, revert
        if (!feeIsPaid) {
            revert ConveyorFeesNotPaid(
                expectedAccumulatedFees,
                contractBalancePostExecution - contractBalancePreExecution,
                expectedAccumulatedFees -
                    (contractBalancePostExecution - contractBalancePreExecution)
            );
        }
    }

    ///@notice Function to withdraw owner fee's accumulated
    function withdrawConveyorFees() external nonReentrant onlyOwner {
        ///@notice Unwrap the the conveyorBalance.
        IWETH(WETH).withdraw(conveyorBalance);

        uint256 withdrawAmount = conveyorBalance;
        ///@notice Set the conveyorBalance to 0 prior to transferring the ETH.
        conveyorBalance = 0;
        _safeTransferETH(owner, withdrawAmount);
    }

    ///@notice Function to confirm ownership transfer of the contract.
    function confirmTransferOwnership() external {
        if (msg.sender != tempOwner) {
            revert UnauthorizedCaller();
        }

        ///@notice Cleanup tempOwner storage.
        tempOwner = address(0);
        owner = msg.sender;
    }

    ///@notice Function to transfer ownership of the contract.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }

        tempOwner = newOwner;
    }
}