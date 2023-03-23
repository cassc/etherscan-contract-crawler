// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";

/// @title BaseController Controller
/// @notice Base contract for all controller contracts
abstract contract BaseController {
    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Address used to identify if it is a Zero address
    address public immutable NULL_ADDRESS = address(0);

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGatewayAddress;

    /// @notice immutable variable with instance of SocketRoute to access route functions
    ISocketRoute public immutable socketRoute;

    /**
     * @notice Construct the base for all controllers.
     * @param _socketGatewayAddress Socketgateway address, an immutable variable to set.
     * @notice initialize the immutable variables of SocketRoute, SocketGateway
     */
    constructor(address _socketGatewayAddress) {
        socketGatewayAddress = _socketGatewayAddress;
        socketRoute = ISocketRoute(_socketGatewayAddress);
    }

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param routeId routeId mapped to the routrImplementation
     * @param data transactionData generated with arguments of bridgeRequest (offchain or by caller)
     * @return returns the bytes response of the route execution (bridging, refuel or swap executions)
     */
    function _executeRoute(
        uint32 routeId,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = socketRoute
            .getRoute(routeId)
            .delegatecall(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }
}