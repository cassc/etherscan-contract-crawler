// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Input, Order} from "../librairies/OrderStructs.sol";

interface IBlurExchange {
    function nonces(address) external view returns (uint256);

    function cancelOrder(Order calldata order) external;

    function cancelOrders(Order[] calldata orders) external;

    function incrementNonce() external;

    function execute(Input calldata sell, Input calldata buy) external payable;
}