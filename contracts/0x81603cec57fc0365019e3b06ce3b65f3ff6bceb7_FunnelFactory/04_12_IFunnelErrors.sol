// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Shared errors for Funnel Contracts and FunnelFactory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelErrors {
    /// @dev Invalid address, could be due to zero address
    /// @param _input address that caused the error.
    error InvalidAddress(address _input);

    /// Error thrown when the token is invalid
    error InvalidToken();

    /// @dev Thrown when attempting to interact with a non-contract.
    error NotContractError();

    /// @dev Error thrown when the permit deadline expires
    error PermitExpired();
}