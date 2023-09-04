// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;


/// @title IAuthenticator
/// @dev Authenticator interface
/// @author Frank Bonnet - <[email protected]>
interface IAuthenticator {
    

    /// @dev Authenticate 
    /// Returns whether `_account` is authenticated
    /// @param _account The account to authenticate
    /// @return whether `_account` is successfully authenticated
    function authenticate(address _account) external view returns (bool);
}