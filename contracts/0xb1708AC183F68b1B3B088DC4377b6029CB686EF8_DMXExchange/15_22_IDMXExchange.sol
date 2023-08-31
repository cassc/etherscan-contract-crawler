// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma abicoder v2;

import {Input, Order} from "../lib/OrderStructs.sol";
import "./IExecutionDelegate.sol";
import "./IPolicyManager.sol";

interface IDMXExchange {
    function nonces(address) external view returns (uint256);

    function close() external;

    function initialize(IExecutionDelegate _executionDelegate, IPolicyManager _policyManager) external;
    
    function cancelOrders(Order[] calldata orders) external;

    function execute(Input calldata sell, Input calldata buy) external payable;

    /* Setters */
    function setExecutionDelegate(IExecutionDelegate _executionDelegate) external;

    function setPolicyManager(IPolicyManager _policyManager) external;

    // function setOracle(address _oracle) external;

    // function setBlockRange(uint256 _blockRange) external;

    function cancelOrder(Order calldata order) external;

    function incrementNonce() external;
}