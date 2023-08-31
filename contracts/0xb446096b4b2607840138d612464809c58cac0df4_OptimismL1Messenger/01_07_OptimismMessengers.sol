// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../../interfaces/IMessenger.sol";

import "../../RestrictedCalls.sol";
import "OpenZeppelin/[email protected]/contracts/vendor/optimism/ICrossDomainMessenger.sol";
import "optimism/Lib_PredeployAddresses.sol";

abstract contract OptimismMessengerBase is IMessenger, RestrictedCalls {
    uint32 private constant MESSAGE_GAS_LIMIT = 1_000_000;

    ICrossDomainMessenger public nativeMessenger;

    function callAllowed(
        address caller,
        address courier
    ) external view returns (bool) {
        return
            courier == address(nativeMessenger) &&
            caller == nativeMessenger.xDomainMessageSender();
    }

    function sendMessage(
        address target,
        bytes calldata message
    ) external restricted(block.chainid) {
        nativeMessenger.sendMessage(target, message, MESSAGE_GAS_LIMIT);
    }
}

contract OptimismL1Messenger is OptimismMessengerBase {
    constructor(address messenger_) {
        nativeMessenger = ICrossDomainMessenger(messenger_);
    }
}

contract OptimismL2Messenger is OptimismMessengerBase {
    constructor() {
        nativeMessenger = ICrossDomainMessenger(
            Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER
        );
    }
}