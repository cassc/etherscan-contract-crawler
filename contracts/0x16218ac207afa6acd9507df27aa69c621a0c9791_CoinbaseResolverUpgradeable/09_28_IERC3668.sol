// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

interface IERC3668 {
    /**
     * @dev Error to raise when an offchain lookup is required.
     * @param sender Sender address (address of this contract).
     * @param urls URLs to request to perform the offchain lookup.
     * @param callData Call data contains all the data to perform the offchain lookup.
     * @param callbackFunction Callback function that should be called after lookup.
     * @param extraData Optional extra data to send.
     */
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );
}