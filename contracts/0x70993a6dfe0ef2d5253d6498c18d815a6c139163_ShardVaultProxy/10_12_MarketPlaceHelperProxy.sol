// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

contract MarketPlaceHelperProxy is Proxy {
    address private immutable MARKETPLACE_HELPER_IMPLEMENTATION;

    constructor(address marketplaceHelperImplementation) {
        MARKETPLACE_HELPER_IMPLEMENTATION = marketplaceHelperImplementation;

        OwnableStorage.layout().owner = msg.sender;
    }

    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        return MARKETPLACE_HELPER_IMPLEMENTATION;
    }

    receive() external payable {}
}