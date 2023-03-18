// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8;

import "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    address DEFAULT_SUBSCRIPTION;

    function __DefaultOperatorFilterer_init(address defaultSubscription, address operatorFilterRegistry)
        internal
        onlyInitializing
    {
        __DefaultOperatorFilterer_init_internal(defaultSubscription, operatorFilterRegistry);
    }

    function __DefaultOperatorFilterer_init_internal(address defaultSubscription, address operatorFilterRegistry)
        internal
    {
        DEFAULT_SUBSCRIPTION = defaultSubscription;
        OperatorFiltererUpgradeable.__OperatorFilterer_init_internal(
            DEFAULT_SUBSCRIPTION,
            operatorFilterRegistry,
            true
        );
    }

    function getDefaultSubscriptionAddress() public view returns (address) {
        return address(DEFAULT_SUBSCRIPTION);
    }
}