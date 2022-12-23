// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../interfaces/IProperty.sol";

interface IDelegate {
    function updateHost(IProperty _property, address _host) external;

    function updatePaymentReceiver(IProperty _property, address _receiver)
        external;

    function cancelByHost(IProperty _property, uint256 _bookingId) external;
}