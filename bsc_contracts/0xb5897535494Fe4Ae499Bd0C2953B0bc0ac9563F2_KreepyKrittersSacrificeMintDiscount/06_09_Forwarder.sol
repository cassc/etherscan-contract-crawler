// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


abstract contract Forwarder is Ownable {

    address immutable public forwarderTarget;

    constructor(address _target) {
        forwarderTarget = _target;
    }

    function forwardCall(bytes calldata callData) external onlyOwner virtual returns (bytes memory result) {
        return Address.functionCall(forwarderTarget, callData);
    }

    function forwardCallWithValue(bytes calldata callData) external onlyOwner payable virtual returns (bytes memory result) {
        return Address.functionCallWithValue(forwarderTarget, callData, msg.value);
    }
}