// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {IncorrectBridgeRatios, ZeroAddressNotAllowed, ArrayLengthMismatch} from "./errors/SocketErrors.sol";

/// @title SocketGatewayContract
/// @notice Socketgateway is a contract with entrypoint functions for all interactions with socket liquidity layer
/// @author Socket Team
contract SocketGatewayTemplate is Ownable {
    using LibBytes for bytes;
    using LibBytes for bytes4;
    using SafeTransferLib for ERC20;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice storage variable to keep track of total number of routes registered in socketgateway
    uint32 public routesCount = 385;

    /// @notice storage variable to keep track of total number of controllers registered in socketgateway
    uint32 public controllerCount;

    address public immutable disabledRouteAddress;

    uint256 public constant CENT_PERCENT = 100e18;

    /// @notice storage mapping for route implementation addresses
    mapping(uint32 => address) public routes;

    /// storage mapping for controller implemenation addresses
    mapping(uint32 => address) public controllers;

    // Events ------------------------------------------------------------------------------------------------------->

    /// @notice Event emitted when a router is added to socketgateway
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    /// @notice Event emitted when a route is disabled
    event RouteDisabled(uint32 indexed routeId);

    /// @notice Event emitted when ownership transfer is requested by socket-gateway-owner
    event OwnershipTransferRequested(
        address indexed _from,
        address indexed _to
    );

    /// @notice Event emitted when a controller is added to socketgateway
    event ControllerAdded(
        uint32 indexed controllerId,
        address indexed controllerAddress
    );

    /// @notice Event emitted when a controller is disabled
    event ControllerDisabled(uint32 indexed controllerId);

    constructor(address _owner, address _disabledRoute) Ownable(_owner) {
        disabledRouteAddress = _disabledRoute;
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /*******************************************
     *          EXTERNAL AND PUBLIC FUNCTIONS  *
     *******************************************/

    /**
     * @notice executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in routeData to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeId route identifier
     * @param routeData functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoute(
        uint32 routeId,
        bytes calldata routeData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = addressAt(routeId).delegatecall(
            routeData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice swaps a token on sourceChain and split it across multiple bridge-recipients
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the swap-data and bridge-data is generated using the function-selector defined as a constant in the implementation address
     * @param swapMultiBridgeRequest request
     */
    function swapAndMultiBridge(
        ISocketRequest.SwapMultiBridgeRequest calldata swapMultiBridgeRequest
    ) external payable {
        uint256 requestLength = swapMultiBridgeRequest.bridgeRouteIds.length;

        if (
            requestLength != swapMultiBridgeRequest.bridgeImplDataItems.length
        ) {
            revert ArrayLengthMismatch();
        }
        uint256 ratioAggregate;
        for (uint256 index = 0; index < requestLength; ) {
            ratioAggregate += swapMultiBridgeRequest.bridgeRatios[index];
        }

        if (ratioAggregate != CENT_PERCENT) {
            revert IncorrectBridgeRatios();
        }

        (bool swapSuccess, bytes memory swapResult) = addressAt(
            swapMultiBridgeRequest.swapRouteId
        ).delegatecall(swapMultiBridgeRequest.swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 amountReceivedFromSwap = abi.decode(swapResult, (uint256));

        uint256 bridgedAmount;

        for (uint256 index = 0; index < requestLength; ) {
            uint256 bridgingAmount;

            // if it is the last bridge request, bridge the remaining amount
            if (index == requestLength - 1) {
                bridgingAmount = amountReceivedFromSwap - bridgedAmount;
            } else {
                // bridging amount is the multiplication of bridgeRatio and amountReceivedFromSwap
                bridgingAmount =
                    (amountReceivedFromSwap *
                        swapMultiBridgeRequest.bridgeRatios[index]) /
                    (CENT_PERCENT);
            }

            // update the bridged amount, this would be used for computation for last bridgeRequest
            bridgedAmount += bridgingAmount;

            bytes memory bridgeImpldata = abi.encodeWithSelector(
                BRIDGE_AFTER_SWAP_SELECTOR,
                bridgingAmount,
                swapMultiBridgeRequest.bridgeImplDataItems[index]
            );

            (bool bridgeSuccess, bytes memory bridgeResult) = addressAt(
                swapMultiBridgeRequest.bridgeRouteIds[index]
            ).delegatecall(bridgeImpldata);

            if (!bridgeSuccess) {
                assembly {
                    revert(add(bridgeResult, 32), mload(bridgeResult))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sequentially executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each dataItem to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeIds a list of route identifiers
     * @param dataItems a list of functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoutes(
        uint32[] calldata routeIds,
        bytes[] calldata dataItems
    ) external payable {
        uint256 routeIdslength = routeIds.length;
        if (routeIdslength != dataItems.length) revert ArrayLengthMismatch();
        for (uint256 index = 0; index < routeIdslength; ) {
            (bool success, bytes memory result) = addressAt(routeIds[index])
                .delegatecall(dataItems[index]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice execute a controller function identified using the controllerId in the request
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param socketControllerRequest socketControllerRequest with controllerId to identify the
     *                                   controllerAddress and byteData constructed using functionSelector
     *                                   of the function being invoked
     * @return bytes data received from the call delegated to controller
     */
    function executeController(
        ISocketGateway.SocketControllerRequest calldata socketControllerRequest
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = controllers[
            socketControllerRequest.controllerId
        ].delegatecall(socketControllerRequest.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice sequentially executes all controller requests
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each controller-request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param controllerRequests a list of socketControllerRequest
     *                              Each controllerRequest contains controllerId to identify the controllerAddress and
     *                              byteData constructed using functionSelector of the function being invoked
     */
    function executeControllers(
        ISocketGateway.SocketControllerRequest[] calldata controllerRequests
    ) external payable {
        for (uint32 index = 0; index < controllerRequests.length; ) {
            (bool success, bytes memory result) = controllers[
                controllerRequests[index].controllerId
            ].delegatecall(controllerRequests[index].data);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(
        address routeAddress
    ) external onlyOwner returns (uint32) {
        uint32 routeId = routesCount;
        routes[routeId] = routeAddress;

        routesCount += 1;

        emit NewRouteAdded(routeId, routeAddress);

        return routeId;
    }

    /**
     * @notice Give Infinite or 0 approval to bridgeRoute for the tokenAddress
               This is a restricted function to be called by only socketGatewayOwner
     */

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external onlyOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).approve(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address controllerAddress
    ) external onlyOwner returns (uint32) {
        uint32 controllerId = controllerCount;

        controllers[controllerId] = controllerAddress;

        controllerCount += 1;

        emit ControllerAdded(controllerId, controllerAddress);

        return controllerId;
    }

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 controllerId) public onlyOwner {
        controllers[controllerId] = disabledRouteAddress;
        emit ControllerDisabled(controllerId);
    }

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external onlyOwner {
        routes[routeId] = disabledRouteAddress;
        emit RouteDisabled(routeId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTIONS    *
     *******************************************/

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) public view returns (address) {
        return addressAt(routeId);
    }

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 controllerId) public view returns (address) {
        return controllers[controllerId];
    }

    function addressAt(uint32 routeId) public view returns (address) {
        if (routeId < 385) {
            if (routeId < 257) {
                if (routeId < 129) {
                    if (routeId < 65) {
                        if (routeId < 33) {
                            if (routeId < 17) {
                                if (routeId < 9) {
                                    if (routeId < 5) {
                                        if (routeId < 3) {
                                            if (routeId == 1) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 3) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 7) {
                                            if (routeId == 5) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 7) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 13) {
                                        if (routeId < 11) {
                                            if (routeId == 9) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 11) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 15) {
                                            if (routeId == 13) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 15) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 25) {
                                    if (routeId < 21) {
                                        if (routeId < 19) {
                                            if (routeId == 17) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 19) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 23) {
                                            if (routeId == 21) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 23) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 29) {
                                        if (routeId < 27) {
                                            if (routeId == 25) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 27) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 31) {
                                            if (routeId == 29) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 31) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 49) {
                                if (routeId < 41) {
                                    if (routeId < 37) {
                                        if (routeId < 35) {
                                            if (routeId == 33) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 35) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 39) {
                                            if (routeId == 37) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 39) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 45) {
                                        if (routeId < 43) {
                                            if (routeId == 41) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 43) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 47) {
                                            if (routeId == 45) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 47) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 57) {
                                    if (routeId < 53) {
                                        if (routeId < 51) {
                                            if (routeId == 49) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 51) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 55) {
                                            if (routeId == 53) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 55) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 61) {
                                        if (routeId < 59) {
                                            if (routeId == 57) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 59) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 63) {
                                            if (routeId == 61) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 63) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 97) {
                            if (routeId < 81) {
                                if (routeId < 73) {
                                    if (routeId < 69) {
                                        if (routeId < 67) {
                                            if (routeId == 65) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 67) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 71) {
                                            if (routeId == 69) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 71) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 77) {
                                        if (routeId < 75) {
                                            if (routeId == 73) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 75) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 79) {
                                            if (routeId == 77) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 79) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 89) {
                                    if (routeId < 85) {
                                        if (routeId < 83) {
                                            if (routeId == 81) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 83) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 87) {
                                            if (routeId == 85) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 87) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 93) {
                                        if (routeId < 91) {
                                            if (routeId == 89) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 91) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 95) {
                                            if (routeId == 93) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 95) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 113) {
                                if (routeId < 105) {
                                    if (routeId < 101) {
                                        if (routeId < 99) {
                                            if (routeId == 97) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 99) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 103) {
                                            if (routeId == 101) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 103) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 109) {
                                        if (routeId < 107) {
                                            if (routeId == 105) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 107) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 111) {
                                            if (routeId == 109) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 111) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 121) {
                                    if (routeId < 117) {
                                        if (routeId < 115) {
                                            if (routeId == 113) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 115) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 119) {
                                            if (routeId == 117) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 119) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 125) {
                                        if (routeId < 123) {
                                            if (routeId == 121) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 123) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 127) {
                                            if (routeId == 125) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 127) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 193) {
                        if (routeId < 161) {
                            if (routeId < 145) {
                                if (routeId < 137) {
                                    if (routeId < 133) {
                                        if (routeId < 131) {
                                            if (routeId == 129) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 131) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 135) {
                                            if (routeId == 133) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 135) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 141) {
                                        if (routeId < 139) {
                                            if (routeId == 137) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 139) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 143) {
                                            if (routeId == 141) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 143) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 153) {
                                    if (routeId < 149) {
                                        if (routeId < 147) {
                                            if (routeId == 145) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 147) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 151) {
                                            if (routeId == 149) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 151) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 157) {
                                        if (routeId < 155) {
                                            if (routeId == 153) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 155) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 159) {
                                            if (routeId == 157) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 159) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 177) {
                                if (routeId < 169) {
                                    if (routeId < 165) {
                                        if (routeId < 163) {
                                            if (routeId == 161) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 163) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 167) {
                                            if (routeId == 165) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 167) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 173) {
                                        if (routeId < 171) {
                                            if (routeId == 169) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 171) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 175) {
                                            if (routeId == 173) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 175) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 185) {
                                    if (routeId < 181) {
                                        if (routeId < 179) {
                                            if (routeId == 177) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 179) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 183) {
                                            if (routeId == 181) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 183) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 189) {
                                        if (routeId < 187) {
                                            if (routeId == 185) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 187) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 191) {
                                            if (routeId == 189) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 191) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 225) {
                            if (routeId < 209) {
                                if (routeId < 201) {
                                    if (routeId < 197) {
                                        if (routeId < 195) {
                                            if (routeId == 193) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 195) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 199) {
                                            if (routeId == 197) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 199) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 205) {
                                        if (routeId < 203) {
                                            if (routeId == 201) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 203) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 207) {
                                            if (routeId == 205) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 207) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 217) {
                                    if (routeId < 213) {
                                        if (routeId < 211) {
                                            if (routeId == 209) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 211) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 215) {
                                            if (routeId == 213) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 215) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 221) {
                                        if (routeId < 219) {
                                            if (routeId == 217) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 219) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 223) {
                                            if (routeId == 221) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 223) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 241) {
                                if (routeId < 233) {
                                    if (routeId < 229) {
                                        if (routeId < 227) {
                                            if (routeId == 225) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 227) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 231) {
                                            if (routeId == 229) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 231) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 237) {
                                        if (routeId < 235) {
                                            if (routeId == 233) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 235) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 239) {
                                            if (routeId == 237) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 239) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 249) {
                                    if (routeId < 245) {
                                        if (routeId < 243) {
                                            if (routeId == 241) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 243) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 247) {
                                            if (routeId == 245) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 247) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 253) {
                                        if (routeId < 251) {
                                            if (routeId == 249) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 251) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 255) {
                                            if (routeId == 253) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 255) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (routeId < 321) {
                    if (routeId < 289) {
                        if (routeId < 273) {
                            if (routeId < 265) {
                                if (routeId < 261) {
                                    if (routeId < 259) {
                                        if (routeId == 257) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 259) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 263) {
                                        if (routeId == 261) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 263) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 269) {
                                    if (routeId < 267) {
                                        if (routeId == 265) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 267) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 271) {
                                        if (routeId == 269) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 271) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 281) {
                                if (routeId < 277) {
                                    if (routeId < 275) {
                                        if (routeId == 273) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 275) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 279) {
                                        if (routeId == 277) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 279) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 285) {
                                    if (routeId < 283) {
                                        if (routeId == 281) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 283) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 287) {
                                        if (routeId == 285) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 287) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 305) {
                            if (routeId < 297) {
                                if (routeId < 293) {
                                    if (routeId < 291) {
                                        if (routeId == 289) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 291) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 295) {
                                        if (routeId == 293) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 295) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 301) {
                                    if (routeId < 299) {
                                        if (routeId == 297) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 299) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 303) {
                                        if (routeId == 301) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 303) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 313) {
                                if (routeId < 309) {
                                    if (routeId < 307) {
                                        if (routeId == 305) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 307) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 311) {
                                        if (routeId == 309) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 311) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 317) {
                                    if (routeId < 315) {
                                        if (routeId == 313) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 315) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 319) {
                                        if (routeId == 317) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 319) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 353) {
                        if (routeId < 337) {
                            if (routeId < 329) {
                                if (routeId < 325) {
                                    if (routeId < 323) {
                                        if (routeId == 321) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 323) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 327) {
                                        if (routeId == 325) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 327) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 333) {
                                    if (routeId < 331) {
                                        if (routeId == 329) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 331) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 335) {
                                        if (routeId == 333) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 335) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 345) {
                                if (routeId < 341) {
                                    if (routeId < 339) {
                                        if (routeId == 337) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 339) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 343) {
                                        if (routeId == 341) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 343) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 349) {
                                    if (routeId < 347) {
                                        if (routeId == 345) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 347) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 351) {
                                        if (routeId == 349) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 351) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 369) {
                            if (routeId < 361) {
                                if (routeId < 357) {
                                    if (routeId < 355) {
                                        if (routeId == 353) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 355) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 359) {
                                        if (routeId == 357) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 359) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 365) {
                                    if (routeId < 363) {
                                        if (routeId == 361) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 363) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 367) {
                                        if (routeId == 365) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 367) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 377) {
                                if (routeId < 373) {
                                    if (routeId < 371) {
                                        if (routeId == 369) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 371) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 375) {
                                        if (routeId == 373) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 375) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 381) {
                                    if (routeId < 379) {
                                        if (routeId == 377) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 379) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 383) {
                                        if (routeId == 381) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 383) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (routes[routeId] == address(0)) revert ZeroAddressNotAllowed();
        return routes[routeId];
    }

    /// @notice fallback function to handle swap, bridge execution
    /// @dev ensure routeId is converted to bytes4 and sent as msg.sig in the transaction
    fallback() external payable {
        address routeAddress = addressAt(uint32(msg.sig));

        bytes memory result;

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 4, sub(calldatasize(), 4))
            // execute function call using the facet
            result := delegatecall(
                gas(),
                routeAddress,
                0,
                sub(calldatasize(), 4),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}