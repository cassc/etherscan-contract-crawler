// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {BaseController} from "./BaseController.sol";

/**
 * @title RefuelSwapAndBridge Controller Implementation
 * @notice Controller with composed actions for Refuel,Swap and Bridge to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract RefuelSwapAndBridgeController is BaseController {
    /// @notice Function-selector to invoke refuel-swap-bridge function
    /// @dev This function selector is to be used while buidling transaction-data
    bytes4 public immutable REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "refuelAndSwapAndBridge((uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to handle refuel followed by Swap and Bridge actions
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param rsbRequest Request with data to execute refuel followed by swap and bridge
     * @return output data from bridging operation
     */
    function refuelAndSwapAndBridge(
        ISocketRequest.RefuelSwapBridgeRequest calldata rsbRequest
    ) public payable returns (bytes memory) {
        _executeRoute(rsbRequest.refuelRouteId, rsbRequest.refuelData);

        // refuel is also a bridging activity via refuel-route-implementation
        bytes memory swapResponseData = _executeRoute(
            rsbRequest.swapRouteId,
            rsbRequest.swapData
        );

        (uint256 swapAmount, ) = abi.decode(
            swapResponseData,
            (uint256, address)
        );

        //sequence of arguments for implData: amount, token, data
        // Bridging the swapAmount received in the preceeding step
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            rsbRequest.bridgeData
        );

        return _executeRoute(rsbRequest.bridgeRouteId, bridgeImpldata);
    }
}