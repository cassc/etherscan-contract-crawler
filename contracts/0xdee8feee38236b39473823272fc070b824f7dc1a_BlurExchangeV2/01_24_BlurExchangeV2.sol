// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable2StepUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import { Executor } from "./Executor.sol";
import "./lib/Constants.sol";
import {
    TakeAsk,
    TakeBid,
    TakeAskSingle,
    TakeBidSingle,
    Order,
    Exchange,
    Fees,
    FeeRate,
    AssetType,
    OrderType,
    Transfer,
    FungibleTransfers,
    StateUpdate,
    AtomicExecution,
    Cancel,
    Listing
} from "./lib/Structs.sol";
import { IBlurExchangeV2 } from "./interfaces/IBlurExchangeV2.sol";
import { ReentrancyGuardUpgradeable } from "./lib/ReentrancyGuardUpgradeable.sol";

contract BlurExchangeV2 is
    IBlurExchangeV2,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    Executor
{
    address public governor;

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor(address delegate, address pool, address proxy) Executor(delegate, pool, proxy) {
        _disableInitializers();
    }

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Reentrancy_init();
        verifyDomain();
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice Governor only function to set the protocol fee rate and recipient
     * @param recipient Protocol fee recipient
     * @param rate Protocol fee rate
     */
    function setProtocolFee(address recipient, uint16 rate) external onlyGovernor {
        if (rate > _MAX_PROTOCOL_FEE_RATE) {
            revert ProtocolFeeTooHigh();
        }
        protocolFee = FeeRate(recipient, rate);
        emit NewProtocolFee(recipient, rate);
    }

    /**
     * @notice Admin only function to set the governor of the exchange
     * @param _governor Address of governor to set
     */
    function setGovernor(address _governor) external onlyOwner {
        governor = _governor;
        emit NewGovernor(_governor);
    }

    /**
     * @notice Admin only function to grant or revoke the approval of an oracle
     * @param oracle Address to set approval of
     * @param approved If the oracle should be approved or not
     */
    function setOracle(address oracle, bool approved) external onlyOwner {
        if (approved) {
            oracles[oracle] = 1;
        } else {
            oracles[oracle] = 0;
        }
        emit SetOracle(oracle, approved);
    }

    /**
     * @notice Admin only function to set the block range
     * @param _blockRange Block range that oracle signatures are valid for
     */
    function setBlockRange(uint256 _blockRange) external onlyOwner {
        blockRange = _blockRange;
        emit NewBlockRange(_blockRange);
    }

    /**
     * @notice Cancel listings by recording their fulfillment
     * @param cancels List of cancels to execute
     */
    function cancelTrades(Cancel[] memory cancels) external {
        uint256 cancelsLength = cancels.length;
        for (uint256 i; i < cancelsLength; ) {
            Cancel memory cancel = cancels[i];
            amountTaken[msg.sender][cancel.hash][cancel.index] += cancel.amount;
            emit CancelTrade(msg.sender, cancel.hash, cancel.index, cancel.amount);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancels all orders by incrementing caller nonce
     */
    function incrementNonce() external {
        emit NonceIncremented(msg.sender, ++nonces[msg.sender]);
    }

    /*//////////////////////////////////////////////////////////////
                          EXECUTION WRAPPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrapper of _takeAsk that verifies an oracle signature of the calldata before executing
     * @param inputs Inputs for _takeAsk
     * @param oracleSignature Oracle signature of inputs
     */
    function takeAsk(
        TakeAsk memory inputs,
        bytes calldata oracleSignature
    )
        public
        payable
        nonReentrant
        verifyOracleSignature(_hashCalldata(msg.sender), oracleSignature)
    {
        _takeAsk(
            inputs.orders,
            inputs.exchanges,
            inputs.takerFee,
            inputs.signatures,
            inputs.tokenRecipient
        );
    }

    /**
     * @notice Wrapper of _takeBid that verifies an oracle signature of the calldata before executing
     * @param inputs Inputs for _takeBid
     * @param oracleSignature Oracle signature of inputs
     */
    function takeBid(
        TakeBid memory inputs,
        bytes calldata oracleSignature
    ) public verifyOracleSignature(_hashCalldata(msg.sender), oracleSignature) {
        _takeBid(inputs.orders, inputs.exchanges, inputs.takerFee, inputs.signatures);
    }

    /**
     * @notice Wrapper of _takeAskSingle that verifies an oracle signature of the calldata before executing
     * @param inputs Inputs for _takeAskSingle
     * @param oracleSignature Oracle signature of inputs
     */
    function takeAskSingle(
        TakeAskSingle memory inputs,
        bytes calldata oracleSignature
    )
        public
        payable
        nonReentrant
        verifyOracleSignature(_hashCalldata(msg.sender), oracleSignature)
    {
        _takeAskSingle(
            inputs.order,
            inputs.exchange,
            inputs.takerFee,
            inputs.signature,
            inputs.tokenRecipient
        );
    }

    /**
     * @notice Wrapper of _takeBidSingle that verifies an oracle signature of the calldata before executing
     * @param inputs Inputs for _takeBidSingle
     * @param oracleSignature Oracle signature of inputs
     */
    function takeBidSingle(
        TakeBidSingle memory inputs,
        bytes calldata oracleSignature
    ) external verifyOracleSignature(_hashCalldata(msg.sender), oracleSignature) {
        _takeBidSingle(inputs.order, inputs.exchange, inputs.takerFee, inputs.signature);
    }

    /*//////////////////////////////////////////////////////////////
                        EXECUTION POOL WRAPPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrapper of takeAskSingle that withdraws ETH from the caller's pool balance prior to executing
     * @param inputs Inputs for takeAskSingle
     * @param oracleSignature Oracle signature of inputs
     * @param amountToWithdraw Amount of ETH to withdraw from the pool
     */
    function takeAskSinglePool(
        TakeAskSingle memory inputs,
        bytes calldata oracleSignature,
        uint256 amountToWithdraw
    ) external payable {
        _withdrawFromPool(msg.sender, amountToWithdraw);

        takeAskSingle(inputs, oracleSignature);
    }

    /**
     * @notice Wrapper of takeAsk that withdraws ETH from the caller's pool balance prior to executing
     * @param inputs Inputs for takeAsk
     * @param oracleSignature Oracle signature of inputs
     * @param amountToWithdraw Amount of ETH to withdraw from the pool
     */
    function takeAskPool(
        TakeAsk memory inputs,
        bytes calldata oracleSignature,
        uint256 amountToWithdraw
    ) external payable {
        _withdrawFromPool(msg.sender, amountToWithdraw);

        takeAsk(inputs, oracleSignature);
    }

    /*//////////////////////////////////////////////////////////////
                          EXECUTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Take a single ask
     * @param order Order of listing to fulfill
     * @param exchange Exchange struct indicating the listing to take and the parameters to match it with
     * @param takerFee Taker fee to be taken
     * @param signature Order signature
     * @param tokenRecipient Address to receive the token transfer
     */
    function _takeAskSingle(
        Order memory order,
        Exchange memory exchange,
        FeeRate memory takerFee,
        bytes memory signature,
        address tokenRecipient
    ) internal {
        Fees memory fees = Fees(protocolFee, takerFee);
        Listing memory listing = exchange.listing;
        uint256 takerAmount = exchange.taker.amount;

        /* Validate the order and listing, revert if not. */
        if (!_validateOrderAndListing(order, OrderType.ASK, exchange, signature, fees)) {
            revert InvalidOrder();
        }

        /* Create single execution batch and insert the transfer. */
        bytes memory executionBatch = _initializeSingleExecution(
            order,
            OrderType.ASK,
            listing.tokenId,
            takerAmount,
            tokenRecipient
        );

        /* Set the fulfillment of the order. */
        unchecked {
            amountTaken[order.trader][bytes32(order.salt)][listing.index] += takerAmount;
        }

        /* Execute the token transfers, revert if not successful. */
        {
            bool[] memory successfulTransfers = _executeNonfungibleTransfers(executionBatch, 1);
            if (!successfulTransfers[0]) {
                revert TokenTransferFailed();
            }
        }

        (
            uint256 totalPrice,
            uint256 protocolFeeAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        ) = _computeFees(listing.price, takerAmount, order.makerFee, fees);

        /* If there are insufficient funds to cover the price with the fees, revert. */
        unchecked {
            if (address(this).balance < totalPrice + takerFeeAmount) {
                revert InsufficientFunds();
            }
        }

        /* Execute ETH transfers. */
        _transferETH(fees.protocolFee.recipient, protocolFeeAmount);
        _transferETH(fees.takerFee.recipient, takerFeeAmount);
        _transferETH(order.makerFee.recipient, makerFeeAmount);
        unchecked {
            _transferETH(order.trader, totalPrice - makerFeeAmount - protocolFeeAmount);
        }

        _emitExecutionEvent(executionBatch, order, listing.index, totalPrice, fees, OrderType.ASK);

        /* Return dust. */
        _transferETH(msg.sender, address(this).balance);
    }

    /**
     * @notice Take a single bid
     * @param order Order of listing to fulfill
     * @param exchange Exchange struct indicating the listing to take and the parameters to match it with
     * @param takerFee Taker fee to be taken
     * @param signature Order signature
     */
    function _takeBidSingle(
        Order memory order,
        Exchange memory exchange,
        FeeRate memory takerFee,
        bytes memory signature
    ) internal {
        Fees memory fees = Fees(protocolFee, takerFee);
        Listing memory listing = exchange.listing;
        uint256 takerAmount = exchange.taker.amount;

        /* Validate the order and listing, revert if not. */
        if (!_validateOrderAndListing(order, OrderType.BID, exchange, signature, fees)) {
            revert InvalidOrder();
        }

        /* Create single execution batch and insert the transfer. */
        bytes memory executionBatch = _initializeSingleExecution(
            order,
            OrderType.BID,
            exchange.taker.tokenId,
            takerAmount,
            msg.sender
        );

        /* Execute the token transfers, revert if not successful. */
        {
            bool[] memory successfulTransfers = _executeNonfungibleTransfers(executionBatch, 1);
            if (!successfulTransfers[0]) {
                revert TokenTransferFailed();
            }
        }

        (
            uint256 totalPrice,
            uint256 protocolFeeAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        ) = _computeFees(listing.price, takerAmount, order.makerFee, fees);

        /* Execute pool transfers and set the fulfillment of the order. */
        address trader = order.trader;
        _transferPool(trader, order.makerFee.recipient, makerFeeAmount);
        _transferPool(trader, fees.takerFee.recipient, takerFeeAmount);
        _transferPool(trader, fees.protocolFee.recipient, protocolFeeAmount);
        unchecked {
            _transferPool(trader, msg.sender, totalPrice - takerFeeAmount - protocolFeeAmount);

            amountTaken[trader][bytes32(order.salt)][listing.index] += exchange.taker.amount;
        }

        _emitExecutionEvent(executionBatch, order, listing.index, totalPrice, fees, OrderType.BID);
    }

    /**
     * @notice Take multiple asks; efficiently verifying and executing the transfers in bulk
     * @param orders List of orders
     * @param exchanges List of exchanges indicating the listing to take and the parameters to match it with
     * @param takerFee Taker fee to be taken on each exchange
     * @param signatures Bytes array of order signatures
     * @param tokenRecipient Address to receive the tokens purchased
     */
    function _takeAsk(
        Order[] memory orders,
        Exchange[] memory exchanges,
        FeeRate memory takerFee,
        bytes memory signatures,
        address tokenRecipient
    ) internal {
        Fees memory fees = Fees(protocolFee, takerFee);

        /**
         * Validate all the orders potentially used in the execution and
         * initialize the arrays for pending fulfillments.
         */
        (bool[] memory validOrders, uint256[][] memory pendingAmountTaken) = _validateOrders(
            orders,
            OrderType.ASK,
            signatures,
            fees
        );

        uint256 exchangesLength = exchanges.length;

        /* Initialize the execution batch structs. */
        (
            bytes memory executionBatch,
            FungibleTransfers memory fungibleTransfers
        ) = _initializeBatch(exchangesLength, OrderType.ASK, tokenRecipient);

        Order memory order;
        Exchange memory exchange;

        uint256 remainingETH = address(this).balance;
        for (uint256 i; i < exchangesLength; ) {
            exchange = exchanges[i];
            order = orders[exchange.index];

            /* Check the listing and exchange is valid and its parent order has already been validated. */
            if (
                _validateListingFromBatch(
                    order,
                    OrderType.ASK,
                    exchange,
                    validOrders,
                    pendingAmountTaken
                )
            ) {
                /* Insert the transfers into the batch. */
                bool inserted;
                (remainingETH, inserted) = _insertExecutionAsk(
                    executionBatch,
                    fungibleTransfers,
                    order,
                    exchange,
                    fees,
                    remainingETH
                );
                if (inserted) {
                    unchecked {
                        pendingAmountTaken[exchange.index][exchange.listing.index] += exchange
                            .taker
                            .amount;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        /* Execute all transfers. */
        _executeBatchTransfer(executionBatch, fungibleTransfers, fees, OrderType.ASK);

        /* Return dust. */
        _transferETH(msg.sender, address(this).balance);
    }

    /**
     * @notice Take multiple bids; efficiently verifying and executing the transfers in bulk
     * @param orders List of orders
     * @param exchanges List of exchanges indicating the listing to take and the parameters to match it with
     * @param takerFee Taker fee to be taken on each exchange
     * @param signatures Bytes array of order signatures
     */
    function _takeBid(
        Order[] memory orders,
        Exchange[] memory exchanges,
        FeeRate memory takerFee,
        bytes memory signatures
    ) internal {
        Fees memory fees = Fees(protocolFee, takerFee);

        /**
         * Validate all the orders potentially used in the execution and
         * initialize the arrays for pending fulfillments.
         */
        (bool[] memory validOrders, uint256[][] memory pendingAmountTaken) = _validateOrders(
            orders,
            OrderType.BID,
            signatures,
            fees
        );

        uint256 exchangesLength = exchanges.length;

        /* Initialize the execution batch structs. */
        (
            bytes memory executionBatch,
            FungibleTransfers memory fungibleTransfers
        ) = _initializeBatch(exchangesLength, OrderType.BID, msg.sender);

        Order memory order;
        Exchange memory exchange;

        for (uint256 i; i < exchangesLength; ) {
            exchange = exchanges[i];
            order = orders[exchange.index];

            /* Check the listing and exchange is valid and its parent order has already been validated. */
            if (
                _validateListingFromBatch(
                    order,
                    OrderType.BID,
                    exchange,
                    validOrders,
                    pendingAmountTaken
                )
            ) {
                /* Insert the transfers into the batch. */
                _insertExecutionBid(executionBatch, fungibleTransfers, order, exchange, fees);

                /* Record the pending fulfillment. */
                unchecked {
                    pendingAmountTaken[exchange.index][exchange.listing.index] += exchange
                        .taker
                        .amount;
                }
            }

            unchecked {
                ++i;
            }
        }

        /* Execute all transfers. */
        _executeBatchTransfer(executionBatch, fungibleTransfers, fees, OrderType.BID);
    }

    /*//////////////////////////////////////////////////////////////
                          EXECUTION HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the ExecutionBatch and FungibleTransfers objects for bulk execution
     * @param exchangesLength Number of exchanges
     * @param orderType Order type
     * @param taker Order taker address
     */
    function _initializeBatch(
        uint256 exchangesLength,
        OrderType orderType,
        address taker
    )
        internal
        pure
        returns (bytes memory executionBatch, FungibleTransfers memory fungibleTransfers)
    {
        /* Initialize the batch. Constructing it manually in calldata packing allows for cheaper delegate execution. */
        uint256 arrayLength = Transfer_size * exchangesLength + One_word;
        uint256 executionBatchLength = ExecutionBatch_base_size + arrayLength;
        executionBatch = new bytes(executionBatchLength);
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            mstore(add(calldataPointer, ExecutionBatch_taker_offset), taker)
            mstore(add(calldataPointer, ExecutionBatch_orderType_offset), orderType)
            mstore(add(calldataPointer, ExecutionBatch_transfers_pointer_offset), ExecutionBatch_transfers_offset) // set the transfers pointer
            mstore(add(calldataPointer, ExecutionBatch_transfers_offset), exchangesLength) // set the length of the transfers array
        }

        /* Initialize the fungible transfers object. */
        AtomicExecution[] memory executions = new AtomicExecution[](exchangesLength);
        address[] memory feeRecipients = new address[](exchangesLength);
        address[] memory makers = new address[](exchangesLength);
        uint256[] memory makerTransfers = new uint256[](exchangesLength);
        uint256[] memory feeTransfers = new uint256[](exchangesLength);
        fungibleTransfers = FungibleTransfers({
            totalProtocolFee: 0,
            totalSellerTransfer: 0,
            totalTakerFee: 0,
            feeRecipientId: 0,
            feeRecipients: feeRecipients,
            makerId: 0,
            makers: makers,
            feeTransfers: feeTransfers,
            makerTransfers: makerTransfers,
            executions: executions
        });
    }

    /**
     * @notice Initialize the ExecutionBatch object for a single execution
     * @param order Order to take a Listing from
     * @param orderType Order type
     * @param tokenId Token id
     * @param amount ERC721/ERC1155 amount
     * @param taker Order taker address
     */
    function _initializeSingleExecution(
        Order memory order,
        OrderType orderType,
        uint256 tokenId,
        uint256 amount,
        address taker
    ) internal pure returns (bytes memory executionBatch) {
        /* Initialize the batch. Constructing it manually in calldata packing allows for cheaper delegate execution. */
        uint256 arrayLength = Transfer_size + One_word;
        uint256 executionBatchLength = ExecutionBatch_base_size + arrayLength;
        executionBatch = new bytes(executionBatchLength);
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            mstore(add(calldataPointer, ExecutionBatch_taker_offset), taker)
            mstore(add(calldataPointer, ExecutionBatch_orderType_offset), orderType)
            mstore(add(calldataPointer, ExecutionBatch_transfers_pointer_offset), ExecutionBatch_transfers_offset) // set the transfers pointer
            mstore(add(calldataPointer, ExecutionBatch_transfers_offset), 1) // set the length of the transfers array
        }

        /* Insert the transfer into the batch. */
        _insertNonfungibleTransfer(executionBatch, order, tokenId, amount);
    }
}