// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IFeeReceiver.sol";

abstract contract FeeProcessor {
    constructor(address payable receiver, bytes32 serviceId) payable {
        IFeeReceiver(receiver).processFee{value: msg.value}(serviceId);
    }
}