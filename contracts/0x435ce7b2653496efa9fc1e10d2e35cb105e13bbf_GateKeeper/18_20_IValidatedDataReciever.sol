// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IValidatedDataReciever {

    /**
     * @notice Function which will be called by desination bridge.
     *
     * @dev Receiver contract must ensure that's from and chainIdFrom correct.
     *
     * @param selector selector which will be called;
     * @param from sender address in source chain;
     * @param chainIdFrom source chain id. TODO change to uint64
     */
    function receiveValidatedData(bytes4 selector, address from, uint64 chainIdFrom) external returns (bool);

}