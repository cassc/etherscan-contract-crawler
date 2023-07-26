// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Validation } from "./Validation.sol";
import "./lib/Constants.sol";
import {
    Order,
    Exchange,
    FungibleTransfers,
    StateUpdate,
    AtomicExecution,
    AssetType,
    Fees,
    FeeRate,
    Listing,
    Taker,
    Transfer,
    OrderType
} from "./lib/Structs.sol";
import { IDelegate } from "./interfaces/IDelegate.sol";
import { IExecutor } from "./interfaces/IExecutor.sol";

abstract contract Executor is IExecutor, Validation {
    address private immutable _DELEGATE;
    address private immutable _POOL;

    constructor(address delegate, address pool, address proxy) Validation(proxy) {
        _DELEGATE = delegate;
        _POOL = pool;
    }

    receive() external payable {
        if (msg.sender != _POOL) {
            revert Unauthorized();
        }
    }

    /**
     * @notice Insert a validated ask listing into the batch if there's sufficient ETH to fulfill
     * @param executionBatch Execution batch
     * @param fungibleTransfers Fungible transfers
     * @param order Order of the listing to insert
     * @param exchange Exchange containing the listing to insert
     * @param fees Protocol and taker fees
     * @param remainingETH Available ETH remaining
     * @return Available ETH remaining after insertion; if the listing was inserted in the batch
     */
    function _insertExecutionAsk(
        bytes memory executionBatch,
        FungibleTransfers memory fungibleTransfers,
        Order memory order,
        Exchange memory exchange,
        Fees memory fees,
        uint256 remainingETH
    ) internal pure returns (uint256, bool) {
        uint256 takerAmount = exchange.taker.amount;

        (
            uint256 totalPrice,
            uint256 protocolFeeAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        ) = _computeFees(exchange.listing.price, takerAmount, order.makerFee, fees);

        /* Only insert the executions if there are sufficient funds to execute. */
        if (remainingETH >= totalPrice + takerFeeAmount) {
            unchecked {
                remainingETH = remainingETH - totalPrice - takerFeeAmount;
            }

            _setAddresses(fungibleTransfers, order);

            uint256 index = _insertNonfungibleTransfer(
                executionBatch,
                order,
                exchange.listing.tokenId,
                takerAmount
            );

            _insertFungibleTransfers(
                fungibleTransfers,
                takerAmount,
                exchange.listing,
                bytes32(order.salt),
                index,
                totalPrice,
                protocolFeeAmount,
                makerFeeAmount,
                takerFeeAmount,
                true
            );

            return (remainingETH, true);
        } else {
            return (remainingETH, false);
        }
    }

    /**
     * @notice Insert a validated bid listing into the batch
     * @param executionBatch Execution batch
     * @param fungibleTransfers Fungible transfers
     * @param order Order of the listing to insert
     * @param exchange Exchange containing listing to insert
     * @param fees Protocol and taker fees
     */
    function _insertExecutionBid(
        bytes memory executionBatch,
        FungibleTransfers memory fungibleTransfers,
        Order memory order,
        Exchange memory exchange,
        Fees memory fees
    ) internal pure {
        uint256 takerAmount = exchange.taker.amount;

        (
            uint256 totalPrice,
            uint256 protocolFeeAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        ) = _computeFees(exchange.listing.price, takerAmount, order.makerFee, fees);

        _setAddresses(fungibleTransfers, order);

        uint256 index = _insertNonfungibleTransfer(
            executionBatch,
            order,
            exchange.taker.tokenId,
            takerAmount
        );

        _insertFungibleTransfers(
            fungibleTransfers,
            takerAmount,
            exchange.listing,
            bytes32(order.salt),
            index,
            totalPrice,
            protocolFeeAmount,
            makerFeeAmount,
            takerFeeAmount,
            false
        );
    }

    /**
     * @notice Insert the nonfungible transfer into the batch
     * @param executionBatch Execution batch
     * @param order Order
     * @param tokenId Token id
     * @param amount Number of token units
     * @return transferIndex Index of the transfer
     */
    function _insertNonfungibleTransfer(
        bytes memory executionBatch,
        Order memory order,
        uint256 tokenId,
        uint256 amount
    ) internal pure returns (uint256 transferIndex) {
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            transferIndex := mload(add(calldataPointer, ExecutionBatch_length_offset))

            let transfersOffset := mload(add(calldataPointer, ExecutionBatch_transfers_pointer_offset))
            let transferPointer := add(
                add(calldataPointer, add(transfersOffset, One_word)),
                mul(transferIndex, Transfer_size)
            )
            mstore(
                add(transferPointer, Transfer_trader_offset),
                mload(add(order, Order_trader_offset))
            ) // set the trader
            mstore(add(transferPointer, Transfer_id_offset), tokenId) // set the token id
            mstore(
                add(transferPointer, Transfer_collection_offset),
                mload(add(order, Order_collection_offset))
            ) // set the collection
            mstore(
                add(transferPointer, Transfer_assetType_offset),
                mload(add(order, Order_assetType_offset))
            ) // set the asset type
            mstore(add(calldataPointer, ExecutionBatch_length_offset), add(transferIndex, 1)) // increment the batch length

            if eq(mload(add(order, Order_assetType_offset)), AssetType_ERC1155) {
                mstore(add(transferPointer, Transfer_amount_offset), amount) // set the amount (don't need to set for ERC721's)
            }
        }
    }

    /**
     * @notice Insert the fungible transfers that need to be executed atomically
     * @param fungibleTransfers Fungible transfers struct
     * @param takerAmount Amount of the listing being taken
     * @param listing Listing to execute
     * @param orderHash Order hash
     * @param index Execution index
     * @param totalPrice Total price of the purchased tokens
     * @param protocolFeeAmount Computed protocol fee
     * @param makerFeeAmount Computed maker fee
     * @param takerFeeAmount Computed taker fee
     * @param makerIsSeller Is the order maker the seller
     */
    function _insertFungibleTransfers(
        FungibleTransfers memory fungibleTransfers,
        uint256 takerAmount,
        Listing memory listing,
        bytes32 orderHash,
        uint256 index,
        uint256 totalPrice,
        uint256 protocolFeeAmount,
        uint256 makerFeeAmount,
        uint256 takerFeeAmount,
        bool makerIsSeller
    ) internal pure {
        uint256 makerId = fungibleTransfers.makerId;
        fungibleTransfers.executions[index].makerId = makerId;
        fungibleTransfers.executions[index].makerFeeRecipientId = fungibleTransfers.feeRecipientId;
        fungibleTransfers.executions[index].stateUpdate = StateUpdate({
            trader: fungibleTransfers.makers[makerId],
            hash: orderHash,
            index: listing.index,
            value: takerAmount,
            maxAmount: listing.amount
        });
        if (makerIsSeller) {
            unchecked {
                fungibleTransfers.executions[index].sellerAmount =
                    totalPrice -
                    protocolFeeAmount -
                    makerFeeAmount;
            }
        } else {
            unchecked {
                fungibleTransfers.executions[index].sellerAmount =
                    totalPrice -
                    protocolFeeAmount -
                    takerFeeAmount;
            }
        }
        fungibleTransfers.executions[index].makerFeeAmount = makerFeeAmount;
        fungibleTransfers.executions[index].takerFeeAmount = takerFeeAmount;
        fungibleTransfers.executions[index].protocolFeeAmount = protocolFeeAmount;
    }

    /**
     * @notice Set the addresses of the maker fee recipient and order maker if different than currently being batched
     * @param fungibleTransfers Fungible transfers struct
     * @param order Parent order of listing being added to the batch
     */
    function _setAddresses(
        FungibleTransfers memory fungibleTransfers,
        Order memory order
    ) internal pure {
        address feeRecipient = order.makerFee.recipient;
        uint256 feeRecipientId = fungibleTransfers.feeRecipientId;
        address currentFeeRecipient = fungibleTransfers.feeRecipients[feeRecipientId];
        if (feeRecipient != currentFeeRecipient) {
            if (currentFeeRecipient == address(0)) {
                fungibleTransfers.feeRecipients[feeRecipientId] = feeRecipient;
            } else {
                unchecked {
                    fungibleTransfers.feeRecipients[++feeRecipientId] = feeRecipient;
                }
                fungibleTransfers.feeRecipientId = feeRecipientId;
            }
        }
        address trader = order.trader;
        uint256 makerId = fungibleTransfers.makerId;
        address currentTrader = fungibleTransfers.makers[makerId];
        if (trader != currentTrader) {
            if (currentTrader == address(0)) {
                fungibleTransfers.makers[makerId] = trader;
            } else {
                unchecked {
                    fungibleTransfers.makers[++makerId] = trader;
                }
                fungibleTransfers.makerId = makerId;
            }
        }
    }

    /**
     * @notice Compute all necessary fees to be taken
     * @param pricePerToken Price per token unit
     * @param takerAmount Number of token units taken (should only be greater than 1 for ERC1155)
     * @param fees Protocol and taker fee set by the transaction
     */
    function _computeFees(
        uint256 pricePerToken,
        uint256 takerAmount,
        FeeRate memory makerFee,
        Fees memory fees
    )
        internal
        pure
        returns (
            uint256 totalPrice,
            uint256 protocolFeeAmount,
            uint256 makerFeeAmount,
            uint256 takerFeeAmount
        )
    {
        totalPrice = pricePerToken * takerAmount;
        makerFeeAmount = (totalPrice * makerFee.rate) / _BASIS_POINTS;
        takerFeeAmount = (totalPrice * fees.takerFee.rate) / _BASIS_POINTS;
        protocolFeeAmount = (totalPrice * fees.protocolFee.rate) / _BASIS_POINTS;
    }

    /*//////////////////////////////////////////////////////////////
                        EXECUTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Execute the transfers by first attempting the nonfungible transfers, for the successful transfers sum the fungible transfers by the recipients and execute
     * @param executionBatch Execution batch struct
     * @param fungibleTransfers Fungible transfers struct
     * @param fees Protocol, maker, taker fees (note: makerFee will be inaccurate at this point in execution)
     * @param orderType Order type
     */
    function _executeBatchTransfer(
        bytes memory executionBatch,
        FungibleTransfers memory fungibleTransfers,
        Fees memory fees,
        OrderType orderType
    ) internal {
        uint256 batchLength;
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            batchLength := mload(add(calldataPointer, ExecutionBatch_length_offset))
        }
        if (batchLength > 0) {
            bool[] memory successfulTransfers = _executeNonfungibleTransfers(
                executionBatch,
                batchLength
            );

            uint256 transfersLength = successfulTransfers.length;
            for (uint256 i; i < transfersLength; ) {
                if (successfulTransfers[i]) {
                    AtomicExecution memory execution = fungibleTransfers.executions[i];
                    FeeRate memory makerFee;
                    uint256 price;
                    unchecked {
                        if (orderType == OrderType.ASK) {
                            fungibleTransfers.makerTransfers[execution.makerId] += execution
                                .sellerAmount; // amount that needs to be sent *to* the order maker
                            price =
                                execution.sellerAmount +
                                execution.protocolFeeAmount +
                                execution.makerFeeAmount;
                        } else {
                            fungibleTransfers.makerTransfers[execution.makerId] +=
                                execution.protocolFeeAmount +
                                execution.makerFeeAmount +
                                execution.takerFeeAmount +
                                execution.sellerAmount; // amount that needs to be taken *from* the order maker
                            price =
                                execution.sellerAmount +
                                execution.protocolFeeAmount +
                                execution.takerFeeAmount;
                        }
                        fungibleTransfers.totalSellerTransfer += execution.sellerAmount; // only for bids
                        fungibleTransfers.totalProtocolFee += execution.protocolFeeAmount;
                        fungibleTransfers.totalTakerFee += execution.takerFeeAmount;
                        fungibleTransfers.feeTransfers[execution.makerFeeRecipientId] += execution
                            .makerFeeAmount;
                        makerFee = FeeRate(
                            fungibleTransfers.feeRecipients[execution.makerFeeRecipientId],
                            uint16((execution.makerFeeAmount * _BASIS_POINTS) / price)
                        );
                    }

                    /* Commit state updates. */
                    StateUpdate memory stateUpdate = fungibleTransfers.executions[i].stateUpdate;
                    {
                        address trader = stateUpdate.trader;
                        bytes32 hash = stateUpdate.hash;
                        uint256 index = stateUpdate.index;
                        uint256 _amountTaken = amountTaken[trader][hash][index];
                        uint256 newAmountTaken = _amountTaken + stateUpdate.value;

                        /* Overfulfilled Listings should be caught prior to inserting into the batch, but this check prevents any misuse. */
                        if (newAmountTaken <= stateUpdate.maxAmount) {
                            amountTaken[trader][hash][index] = newAmountTaken;
                        } else {
                            revert OrderFulfilled();
                        }
                    }

                    _emitExecutionEventFromBatch(
                        executionBatch,
                        price,
                        makerFee,
                        fees,
                        stateUpdate,
                        orderType,
                        i
                    );
                }

                unchecked {
                    ++i;
                }
            }

            if (orderType == OrderType.ASK) {
                /* Transfer the payments to the sellers. */
                uint256 makersLength = fungibleTransfers.makerId + 1;
                for (uint256 i; i < makersLength; ) {
                    _transferETH(fungibleTransfers.makers[i], fungibleTransfers.makerTransfers[i]);
                    unchecked {
                        ++i;
                    }
                }

                /* Transfer the fees to the fee recipients. */
                uint256 feesLength = fungibleTransfers.feeRecipientId + 1;
                for (uint256 i; i < feesLength; ) {
                    _transferETH(
                        fungibleTransfers.feeRecipients[i],
                        fungibleTransfers.feeTransfers[i]
                    );
                    unchecked {
                        ++i;
                    }
                }

                /* Transfer the protocol fees. */
                _transferETH(fees.protocolFee.recipient, fungibleTransfers.totalProtocolFee);

                /* Transfer the taker fees. */
                _transferETH(fees.takerFee.recipient, fungibleTransfers.totalTakerFee);
            } else {
                /* Take the pool funds from the buyers. */
                uint256 makersLength = fungibleTransfers.makerId + 1;
                for (uint256 i; i < makersLength; ) {
                    _transferPool(
                        fungibleTransfers.makers[i],
                        address(this),
                        fungibleTransfers.makerTransfers[i]
                    );
                    unchecked {
                        ++i;
                    }
                }

                /* Transfer the payment to the seller. */
                _transferPool(address(this), msg.sender, fungibleTransfers.totalSellerTransfer);

                /* Transfer the fees to the fee recipients. */
                uint256 feesLength = fungibleTransfers.feeRecipientId + 1;
                for (uint256 i; i < feesLength; ) {
                    _transferPool(
                        address(this),
                        fungibleTransfers.feeRecipients[i],
                        fungibleTransfers.feeTransfers[i]
                    );
                    unchecked {
                        ++i;
                    }
                }

                /* Transfer the protocol fees. */
                _transferPool(
                    address(this),
                    fees.protocolFee.recipient,
                    fungibleTransfers.totalProtocolFee
                );

                /* Transfer the taker fees. */
                _transferPool(
                    address(this),
                    fees.takerFee.recipient,
                    fungibleTransfers.totalTakerFee
                );
            }
        }
    }

    /**
     * @notice Attempt to execute a series of nonfungible transfers through the delegate; reverts will be skipped
     * @param executionBatch Execution batch struct
     * @param batchIndex Current available transfer slot in the batch
     * @return Array indicating which transfers were successful
     */
    function _executeNonfungibleTransfers(
        bytes memory executionBatch,
        uint256 batchIndex
    ) internal returns (bool[] memory) {
        address delegate = _DELEGATE;

        /* Initialize the memory space for the successful transfers array returned from the Delegate call. */
        uint256 successfulTransfersPointer;
        assembly {
            successfulTransfersPointer := mload(Memory_pointer)
            /* Need to shift the free memory pointer ahead one word to account for the array pointer returned from the call. */
            mstore(Memory_pointer, add(successfulTransfersPointer, One_word))
        }

        bool[] memory successfulTransfers = new bool[](batchIndex);
        assembly {
            let size := mload(executionBatch)
            let selectorPointer := add(executionBatch, ExecutionBatch_selector_offset)
            mstore(selectorPointer, shr(Bytes4_shift, Delegate_transfer_selector))
            let success := call(
                gas(),
                delegate,
                0,
                add(selectorPointer, Delegate_transfer_calldata_offset),
                sub(size, Delegate_transfer_calldata_offset),
                successfulTransfersPointer,
                add(0x40, mul(batchIndex, One_word))
            )
        }
        return successfulTransfers;
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer ETH
     * @param to Recipient address
     * @param amount Amount of ETH to send
     */
    function _transferETH(address to, uint256 amount) internal {
        if (amount > 0) {
            bool success;
            assembly {
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            if (!success) {
                revert ETHTransferFailed();
            }
        }
    }

    /**
     * @notice Transfer pool funds on behalf of a user
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to send
     */
    function _transferPool(address from, address to, uint256 amount) internal {
        if (amount > 0) {
            bool success;
            address pool = _POOL;
            assembly {
                let x := mload(Memory_pointer)
                mstore(x, ERC20_transferFrom_selector)
                mstore(add(x, ERC20_transferFrom_from_offset), from)
                mstore(add(x, ERC20_transferFrom_to_offset), to)
                mstore(add(x, ERC20_transferFrom_amount_offset), amount)
                success := call(gas(), pool, 0, x, ERC20_transferFrom_size, 0, 0)
            }
            if (!success) {
                revert PoolTransferFailed();
            }
        }
    }

    /**
     * @notice Deposit ETH to user's pool funds
     * @param to Recipient address
     * @param amount Amount of ETH to deposit
     */
    function _depositPool(address to, uint256 amount) internal {
        bool success;
        address pool = _POOL;
        assembly {
            let x := mload(Memory_pointer)
            mstore(x, Pool_deposit_selector)
            mstore(add(x, Pool_deposit_user_offset), to)
            success := call(gas(), pool, amount, x, Pool_deposit_size, 0, 0)
        }
        if (!success) {
            revert PoolDepositFailed();
        }
    }

    /**
     * @notice Withdraw ETH from user's pool funds
     * @param from Address to withdraw from
     * @param amount Amount of ETH to withdraw
     */
    function _withdrawFromPool(address from, uint256 amount) internal {
        bool success;
        address pool = _POOL;
        assembly {
            let x := mload(Memory_pointer)
            mstore(x, Pool_withdrawFrom_selector)
            mstore(add(x, Pool_withdrawFrom_from_offset), from)
            mstore(add(x, Pool_withdrawFrom_to_offset), address())
            mstore(add(x, Pool_withdrawFrom_amount_offset), amount)
            success := call(gas(), pool, 0, x, Pool_withdrawFrom_size, 0, 0)
        }
        if (!success) {
            revert PoolWithdrawFromFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          EVENT EMITTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emit Execution event from a single execution
     * @param executionBatch Execution batch struct
     * @param price Price of the token purchased
     * @param fees Protocol, maker, and taker fees taken
     * @param stateUpdate Fulfillment to be recorded with a successful execution
     * @param orderType Order type
     * @param transferIndex Index of the transfer corresponding to the execution
     */
    function _emitExecutionEventFromBatch(
        bytes memory executionBatch,
        uint256 price,
        FeeRate memory makerFee,
        Fees memory fees,
        StateUpdate memory stateUpdate,
        OrderType orderType,
        uint256 transferIndex
    ) internal {
        Transfer memory transfer;
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            let transfersOffset := mload(add(calldataPointer, ExecutionBatch_transfers_pointer_offset))
            transfer := add(
                add(calldataPointer, add(transfersOffset, One_word)),
                mul(transferIndex, Transfer_size)
            )
        }

        _emitOptimalExecutionEvent(
            transfer,
            stateUpdate.hash,
            stateUpdate.index,
            price,
            makerFee,
            fees,
            orderType
        );
    }

    /**
     * @notice Emit the Execution event that minimizes the number of bytes in the log
     * @param transfer The nft transfer
     * @param orderHash Order hash
     * @param listingIndex Index of the listing being fulfilled within the order
     * @param price Price of the token purchased
     * @param makerFee Maker fees taken
     * @param fees Protocol, and taker fees taken
     * @param orderType Order type
     */
    function _emitOptimalExecutionEvent(
        Transfer memory transfer,
        bytes32 orderHash,
        uint256 listingIndex,
        uint256 price,
        FeeRate memory makerFee,
        Fees memory fees,
        OrderType orderType
    ) internal {
        if (
            // see _insertNonfungibleTransfer; ERC721 transfers don't set the transfer amount,
            // so we can assume the transfer amount and not check it
            transfer.assetType == AssetType.ERC721 &&
            fees.protocolFee.rate == 0 &&
            transfer.id < 1 << (11 * 8) &&
            listingIndex < 1 << (1 * 8) &&
            price < 1 << (11 * 8)
        ) {
            if (makerFee.rate == 0 && fees.takerFee.rate == 0) {
                emit Execution721Packed(
                    orderHash,
                    packTokenIdListingIndexTrader(transfer.id, listingIndex, transfer.trader),
                    packTypePriceCollection(orderType, price, transfer.collection)
                );
                return;
            } else if (makerFee.rate == 0) {
                emit Execution721TakerFeePacked(
                    orderHash,
                    packTokenIdListingIndexTrader(transfer.id, listingIndex, transfer.trader),
                    packTypePriceCollection(orderType, price, transfer.collection),
                    packFee(fees.takerFee)
                );
                return;
            } else if (fees.takerFee.rate == 0) {
                emit Execution721MakerFeePacked(
                    orderHash,
                    packTokenIdListingIndexTrader(transfer.id, listingIndex, transfer.trader),
                    packTypePriceCollection(orderType, price, transfer.collection),
                    packFee(makerFee)
                );
                return;
            }
        }

        emit Execution({
            transfer: transfer,
            orderHash: orderHash,
            listingIndex: listingIndex,
            price: price,
            makerFee: makerFee,
            fees: fees,
            orderType: orderType
        });
    }

    /**
     * @notice Emit Execution event from a single execution
     * @param executionBatch Execution batch struct
     * @param order Order being fulfilled
     * @param listingIndex Index of the listing being fulfilled within the order
     * @param price Price of the token purchased
     * @param fees Protocol, and taker fees taken
     * @param orderType Order type
     */
    function _emitExecutionEvent(
        bytes memory executionBatch,
        Order memory order,
        uint256 listingIndex,
        uint256 price,
        Fees memory fees,
        OrderType orderType
    ) internal {
        Transfer memory transfer;
        assembly {
            let calldataPointer := add(executionBatch, ExecutionBatch_calldata_offset)
            let transfersOffset := mload(add(calldataPointer, ExecutionBatch_transfers_pointer_offset))
            transfer := add(calldataPointer, add(transfersOffset, One_word))
        }

        _emitOptimalExecutionEvent(
            transfer,
            bytes32(order.salt),
            listingIndex,
            price,
            order.makerFee,
            fees,
            orderType
        );
    }

    function packTokenIdListingIndexTrader(
        uint256 tokenId,
        uint256 listingIndex,
        address trader
    ) private pure returns (uint256) {
        return (tokenId << (21 * 8)) | (listingIndex << (20 * 8)) | uint160(trader);
    }

    function packTypePriceCollection(
        OrderType orderType,
        uint256 price,
        address collection
    ) private pure returns (uint256) {
        return (uint256(orderType) << (31 * 8)) | (price << (20 * 8)) | uint160(collection);
    }

    function packFee(FeeRate memory fee) private pure returns (uint256) {
        return (uint256(fee.rate) << (20 * 8)) | uint160(fee.recipient);
    }

    uint256[50] private __gap;
}