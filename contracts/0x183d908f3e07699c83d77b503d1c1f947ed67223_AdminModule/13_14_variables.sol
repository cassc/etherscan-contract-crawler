// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Constants {
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH_ADDR = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH_ADDR = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    // Permissible Deviation of Ratio, 0.2%. When the leveraged position is just established,
    // the ratio will be very close to the threshold value, and the value of stETH does
    // not increase with block number. However, some protocols such as Aave increase the
    // debt with block number. If the target ratio is 60%, then assuming 60.2% is also safe.
    uint256 public constant PERMISSIBLE_LIMIT = 2e15;
    // The Minimum Safe Aggregation Ratio cannot be lower than 70%.
    uint256 public constant MIN_SAFE_AGGREGATED_RATIO = 70e16;
    // The Maximum Safe Aggregation Ratio cannot be higher than 95%.
    uint256 public constant MAX_SAFE_AGGREGATED_RATIO = 95e16;
}

contract Variables is Constants {
    // Specify the operational logic for the lending protocol,
    // where the corresponding method will be delegatecalled when performing operations.
    address public lendingLogic;
    // The intermediary contract for executing flash loan operations.
    address public flashloanHelper;
    // The address of the flag used to prevent flash loan re-entry attacks.
    address public executor;
    // The token contract used to record the proportional equity of users.
    address public vault;
    // The address of the recipient for performance fees.
    address public feeReceiver;
    // The exchange rate used during user deposit and withdrawal operations.
    uint256 public exchangePrice;
    // The exchange rate used when calculating performance fees.
    // Performance fees will be recorded when the real exchange rate exceeds this rate.
    uint256 public revenueExchangePrice;
    // The amount of performance fees recorded after profits are generated in the strategy pool,
    // collected in the core asset stETH.
    uint256 public revenue;
    // The percentage of performance fees collected, where 1000 corresponds to 10%.
    uint256 public revenueRate;
    // The safe debt collateralization ratio for the entire strategy pool.
    uint256 public safeAggregatedRatio;
    // Map of safety line in the lending protocol. (protocolId => safeProtocolRatio)
    mapping(uint8 => uint256) public safeProtocolRatio;
    // Map of availability of the lending protocol. (protocolId => isAvailableProtocol)
    mapping(uint8 => bool) public availableProtocol;
    // Map of legitimacy of the rebalancer. (address => isRebalancer)
    mapping(address => bool) public rebalancer;
}