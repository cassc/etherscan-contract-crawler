// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interface for the service registration token utility manipulation.
interface IServiceTokenUtility {
    /// @dev Creates a record with the token-related information for the specified service.
    /// @param serviceId Service Id.
    /// @param token Token address.
    /// @param agentIds Set of agent Ids.
    /// @param bonds Set of correspondent bonds.
    function createWithToken(
        uint256 serviceId,
        address token,
        uint32[] memory agentIds,
        uint256[] memory bonds
    ) external;

    /// @dev Resets a record with token and security deposit data.
    /// @param serviceId Service Id.
    function resetServiceToken(uint256 serviceId) external;

    /// @dev Deposit a token security deposit for the service registration after its activation.
    /// @param serviceId Service Id.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function activateRegistrationTokenDeposit(uint256 serviceId) external returns (bool isTokenSecured);

    /// @dev Deposits bonded tokens from the operator during the agent instance registration.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @param agentIds Set of agent Ids for corresponding agent instances opertor is registering.
    /// @return isTokenSecured True if the service Id is token secured, false if ETH secured otherwise.
    function registerAgentsTokenDeposit(
        address operator,
        uint256 serviceId,
        uint32[] memory agentIds
    ) external returns (bool isTokenSecured);

    /// @dev Withdraws a token security deposit to the service owner after the service termination.
    /// @param serviceId Service Id.
    /// @return securityRefund Returned token security deposit, or zero if the service is ETH-secured.
    function terminateTokenRefund(uint256 serviceId) external returns (uint256 securityRefund);

    /// @dev Withdraws bonded tokens to the operator during the unbond phase.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return refund Returned bonded token amount, or zero if the service is ETH-secured.
    function unbondTokenRefund(address operator, uint256 serviceId) external returns (uint256 refund);

    /// @dev Gets service token secured status.
    /// @param serviceId Service Id.
    /// @return True if the service Id is token secured.
    function isTokenSecuredService(uint256 serviceId) external view returns (bool);
}