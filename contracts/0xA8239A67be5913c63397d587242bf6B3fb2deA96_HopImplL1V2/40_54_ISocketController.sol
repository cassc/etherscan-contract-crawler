// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketController
 * @notice Interface for SocketController functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 *      only restriction is that this should have functions to manage controllers
 * @author Socket dot tech.
 */
interface ISocketController {
    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param _controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address _controllerAddress
    ) external returns (uint32);

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param _controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 _controllerId) external;

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param _controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 _controllerId) external returns (address);
}