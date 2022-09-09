// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "../IOrder.sol";


interface ICedarOrderFillerV0 {
    // Submit a signed order - supports a on-demand signed claim (e.g. fiat payment taken by API) with no on-chain payment being taken,
    function fillOrder(IOrderV0.Order calldata order, bytes calldata signature) external;
}