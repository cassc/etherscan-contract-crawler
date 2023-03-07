// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {TokenHelper} from "../../../core/asset/TokenHelper.sol";

import {IGasVendor, GasFee} from "../IGasVendor.sol";

contract XRelayGasVendor is IGasVendor {
    address private immutable _relay;

    constructor(address relay_) {
        _relay = relay_;
    }

    function getGasFee(address msgSender_, bytes calldata msgData_) external view returns (GasFee memory fee) {
        if (msgSender_ == _relay) {
            (fee.collector, fee.amount) = abi.decode(msgData_[msgData_.length - 64:], (address, uint256));
            fee.token = TokenHelper.NATIVE_TOKEN;
        }
    }
}