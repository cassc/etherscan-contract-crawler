// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketGateway
 * @notice Interface for SocketGateway functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
interface ISocketGateway {
    /**
     * @notice Request-struct for controllerRequests
     * @dev ensure the value for data is generated using the function-selectors defined in the controllerImplementation contracts
     */
    struct SocketControllerRequest {
        // controllerId is the id mapped to the controllerAddress
        uint32 controllerId;
        // transactionImplData generated off-chain or by caller using function-selector of the controllerContract
        bytes data;
    }

    // @notice view to get owner-address
    function owner() external view returns (address);
}