// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface for routeManagement functions in SocketGateway.
 * @author Socket dot tech.
 */
interface ISocketRoute {
    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(address routeAddress) external returns (uint256);

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external;

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) external view returns (address);
}