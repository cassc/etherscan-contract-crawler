// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library CommonError {
    error ZeroAddressSet();
    error InvalidParams();
    /// @dev revert when to caller is not signer
    error NotSigner();
    error SignatureExpired();
}