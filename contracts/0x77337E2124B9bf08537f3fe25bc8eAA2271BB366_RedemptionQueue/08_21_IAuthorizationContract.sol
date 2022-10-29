// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @author Swarm Markets
/// @title IAuthorizationContracts
/// @notice Provided interface to interact with any contract to check
/// @notice authorization to a certain transaction
interface IAuthorizationContract {
    function isAccountAuthorized(address _user) external view returns (bool);

    function isTxAuthorized(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
}