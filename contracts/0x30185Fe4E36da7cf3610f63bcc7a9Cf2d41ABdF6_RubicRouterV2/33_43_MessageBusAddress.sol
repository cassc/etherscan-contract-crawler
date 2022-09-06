// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

abstract contract MessageBusAddress {
    event MessageBusUpdated(address messageBus);

    address public messageBus;
}