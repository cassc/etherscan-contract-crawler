// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant OPERATION_STORAGE = "OperationStorage_2";
string constant OPERATION_EXECUTOR = "OperationExecutor_2";
string constant OPERATIONS_REGISTRY = "OperationsRegistry_2";
string constant CHAINLOG_VIEWER = "ChainLogView";
string constant ONE_INCH_AGGREGATOR = "OneInchAggregator";
string constant DS_GUARD_FACTORY = "DSGuardFactory";
string constant WETH = "WETH";
string constant DAI = "DAI";
uint256 constant RAY = 10 ** 27;
bytes32 constant NULL = "";

/**
 * @dev We do not include patch versions in contract names to allow
 * for hotfixes of Action dma-contracts
 * and to limit updates to TheGraph
 * if the types encoded in emitted events change then use a minor version and
 * update the ServiceRegistry with a new entry
 * and update TheGraph decoding accordingly
 */
string constant POSITION_CREATED_ACTION = "PositionCreated";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;