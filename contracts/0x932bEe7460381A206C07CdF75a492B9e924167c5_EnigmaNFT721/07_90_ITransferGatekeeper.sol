// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @title ITransferGatekeeper
/// @notice an interface that allows an asset transfer to be guard.

interface ITransferGatekeeper {
    /**
     * @param _from the address that owns what's being transfered
     * @param _to the address that would receive what's being transfered
     * @param _proxy the address that wants to transfer
     * @param _data any other aditional data that might be relevant to allow/block the transfer
     * @dev Returns true if this transfer is allowed under current context
     */
    function canTransfer(
        address _from,
        address _to,
        address _proxy,
        bytes memory _data
    ) external view returns (bool);
}