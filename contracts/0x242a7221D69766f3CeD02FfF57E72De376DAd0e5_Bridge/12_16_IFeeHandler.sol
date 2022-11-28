// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IFeeHandler {
    /// @notice Collects fee for deposit.
    /// @param sender Sender of the deposit.
    /// @param fromDomainID ID of the source chain.
    /// @param destinationDomainID ID of chain deposit will be bridged to.
    /// @param resourceID ResourceID to be used when making deposits.
    function collectFee(
        address sender,
        uint8 fromDomainID,
        uint8 destinationDomainID,
        bytes32 resourceID
    ) external payable;

    /// @notice gets fee for deposit.
    function fee() external view returns (uint256);
}