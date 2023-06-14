// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library CommonError {
    error ZeroAddressSet();
    error InvalidParams();
    /// @dev revert when to caller is not signer
    error NotSigner();
    error NotPortal();
    error ExhumeeNotTombStoneOwner();
    error NotShovelOwner();
    error TombstoneNotEngraved();
    error SignatureExpired();
}