// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";

interface ILooksRareAggregator {
    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @param orders Orders to be executed by the marketplace
     * @param ordersExtraData Extra data for each order, specific for each marketplace
     * @param extraData Extra data specific for each marketplace
     */
    struct TradeData {
        address proxy;
        bytes4 selector;
        BasicOrder[] orders;
        bytes[] ordersExtraData;
        bytes extraData;
    }

    /**
     * @notice Execute NFT sweeps in different marketplaces in a
     *         single transaction
     * @param tokenTransfers Aggregated ERC20 token transfers for all markets
     * @param tradeData Data object to be passed downstream to each
     *                  marketplace's proxy for execution
     * @param originator The address that originated the transaction,
     *                   hard coded as msg.sender if it is called directly
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing)
     *                 or partial trades
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        TradeData[] calldata tradeData,
        address originator,
        address recipient,
        bool isAtomic
    ) external payable;

    /**
     * @notice Emitted when a marketplace proxy's function is enabled.
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    event FunctionAdded(address proxy, bytes4 selector);

    /**
     * @notice Emitted when a marketplace proxy's function is disabled.
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    event FunctionRemoved(address proxy, bytes4 selector);

    /**
     * @notice Emitted when execute is complete
     * @param sweeper The address that submitted the transaction
     */
    event Sweep(address sweeper);

    error AlreadySet();
    error ETHTransferFail();
    error InvalidFunction();
    error UseERC20EnabledLooksRareAggregator();
}