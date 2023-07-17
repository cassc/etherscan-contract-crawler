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
contract SocketGateway is Ownable {
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
                                                    0x8cd6BaCDAe46B449E2e5B34e348A4eD459c84D50;
                                            } else {
                                                return
                                                    0x31524750Cd865fF6A3540f232754Fb974c18585C;
                                            }
                                        } else {
                                            if (routeId == 3) {
                                                return
                                                    0xEd9b37342BeC8f3a2D7b000732ec87498aA6EC6a;
                                            } else {
                                                return
                                                    0xE8704Ef6211F8988Ccbb11badC89841808d66890;
                                            }
                                        }
                                    } else {
                                        if (routeId < 7) {
                                            if (routeId == 5) {
                                                return
                                                    0x9aFF58C460a461578C433e11C4108D1c4cF77761;
                                            } else {
                                                return
                                                    0x2D1733886cFd465B0B99F1492F40847495f334C5;
                                            }
                                        } else {
                                            if (routeId == 7) {
                                                return
                                                    0x715497Be4D130F04B8442F0A1F7a9312D4e54FC4;
                                            } else {
                                                return
                                                    0x90C8a40c38E633B5B0e0d0585b9F7FA05462CaaF;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 13) {
                                        if (routeId < 11) {
                                            if (routeId == 9) {
                                                return
                                                    0xa402b70FCfF3F4a8422B93Ef58E895021eAdE4F6;
                                            } else {
                                                return
                                                    0xc1B718522E15CD42C4Ac385a929fc2B51f5B892e;
                                            }
                                        } else {
                                            if (routeId == 11) {
                                                return
                                                    0xa97bf2f7c26C43c010c349F52f5eA5dC49B2DD38;
                                            } else {
                                                return
                                                    0x969423d71b62C81d2f28d707364c9Dc4a0764c53;
                                            }
                                        }
                                    } else {
                                        if (routeId < 15) {
                                            if (routeId == 13) {
                                                return
                                                    0xF86729934C083fbEc8C796068A1fC60701Ea1207;
                                            } else {
                                                return
                                                    0xD7cC2571F5823caCA26A42690D2BE7803DD5393f;
                                            }
                                        } else {
                                            if (routeId == 15) {
                                                return
                                                    0x7c8837a279bbbf7d8B93413763176de9F65d5bB9;
                                            } else {
                                                return
                                                    0x13b81C27B588C07D04458ed7dDbdbD26D1e39bcc;
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
                                                    0x52560Ac678aFA1345D15474287d16Dc1eA3F78aE;
                                            } else {
                                                return
                                                    0x1E31e376551459667cd7643440c1b21CE69065A0;
                                            }
                                        } else {
                                            if (routeId == 19) {
                                                return
                                                    0xc57D822CB3288e7b97EF8f8af0EcdcD1B783529B;
                                            } else {
                                                return
                                                    0x2197A1D9Af24b4d6a64Bff95B4c29Fcd3Ff28C30;
                                            }
                                        }
                                    } else {
                                        if (routeId < 23) {
                                            if (routeId == 21) {
                                                return
                                                    0xE3700feAa5100041Bf6b7AdBA1f72f647809Fd00;
                                            } else {
                                                return
                                                    0xc02E8a0Fdabf0EeFCEA025163d90B5621E2b9948;
                                            }
                                        } else {
                                            if (routeId == 23) {
                                                return
                                                    0xF5144235E2926cAb3c69b30113254Fa632f72d62;
                                            } else {
                                                return
                                                    0xBa3F92313B00A1f7Bc53b2c24EB195c8b2F57682;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 29) {
                                        if (routeId < 27) {
                                            if (routeId == 25) {
                                                return
                                                    0x77a6856fe1fFA5bEB55A1d2ED86E27C7c482CB76;
                                            } else {
                                                return
                                                    0x4826Ff4e01E44b1FCEFBfb38cd96687Eb7786b44;
                                            }
                                        } else {
                                            if (routeId == 27) {
                                                return
                                                    0x55FF3f5493cf5e80E76DEA7E327b9Cd8440Af646;
                                            } else {
                                                return
                                                    0xF430Db544bE9770503BE4aa51997aA19bBd5BA4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 31) {
                                            if (routeId == 29) {
                                                return
                                                    0x0f166446ce1484EE3B0663E7E67DF10F5D240115;
                                            } else {
                                                return
                                                    0x6365095D92537f242Db5EdFDd572745E72aC33d9;
                                            }
                                        } else {
                                            if (routeId == 31) {
                                                return
                                                    0x5c7BC93f06ce3eAe75ADf55E10e23d2c1dE5Bc65;
                                            } else {
                                                return
                                                    0xe46383bAD90d7A08197ccF08972e9DCdccCE9BA4;
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
                                                    0xf0f21710c071E3B728bdc4654c3c0b873aAaa308;
                                            } else {
                                                return
                                                    0x63Bc9ed3AcAAeB0332531C9fB03b0a2352E9Ff25;
                                            }
                                        } else {
                                            if (routeId == 35) {
                                                return
                                                    0xd1CE808625CB4007a1708824AE82CdB0ece57De9;
                                            } else {
                                                return
                                                    0x57BbB148112f4ba224841c3FE018884171004661;
                                            }
                                        }
                                    } else {
                                        if (routeId < 39) {
                                            if (routeId == 37) {
                                                return
                                                    0x037f7d6933036F34DFabd40Ff8e4D789069f92e3;
                                            } else {
                                                return
                                                    0xeF978c280915CfF3Dca4EDfa8932469e40ADA1e1;
                                            }
                                        } else {
                                            if (routeId == 39) {
                                                return
                                                    0x92ee9e071B13f7ecFD62B7DED404A16CBc223CD3;
                                            } else {
                                                return
                                                    0x94Ae539c186e41ed762271338Edf140414D1E442;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 45) {
                                        if (routeId < 43) {
                                            if (routeId == 41) {
                                                return
                                                    0x30A64BBe4DdBD43dA2368EFd1eB2d80C10d84DAb;
                                            } else {
                                                return
                                                    0x3aEABf81c1Dc4c1b73d5B2a95410f126426FB596;
                                            }
                                        } else {
                                            if (routeId == 43) {
                                                return
                                                    0x25b08aB3D0C8ea4cC9d967b79688C6D98f3f563a;
                                            } else {
                                                return
                                                    0xea40cB15C9A3BBd27af6474483886F7c0c9AE406;
                                            }
                                        }
                                    } else {
                                        if (routeId < 47) {
                                            if (routeId == 45) {
                                                return
                                                    0x9580113Cc04e5a0a03359686304EF3A80b936Dd3;
                                            } else {
                                                return
                                                    0xD211c826d568957F3b66a3F4d9c5f68cCc66E619;
                                            }
                                        } else {
                                            if (routeId == 47) {
                                                return
                                                    0xCEE24D0635c4C56315d133b031984d4A6f509476;
                                            } else {
                                                return
                                                    0x3922e6B987983229798e7A20095EC372744d4D4c;
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
                                                    0x2d92D03413d296e1F31450479349757187F2a2b7;
                                            } else {
                                                return
                                                    0x0fe5308eE90FC78F45c89dB6053eA859097860CA;
                                            }
                                        } else {
                                            if (routeId == 51) {
                                                return
                                                    0x08Ba68e067C0505bAF0C1311E0cFB2B1B59b969c;
                                            } else {
                                                return
                                                    0x9bee5DdDF75C24897374f92A534B7A6f24e97f4a;
                                            }
                                        }
                                    } else {
                                        if (routeId < 55) {
                                            if (routeId == 53) {
                                                return
                                                    0x1FC5A90B232208704B930c1edf82FFC6ACc02734;
                                            } else {
                                                return
                                                    0x5b1B0417cb44c761C2a23ee435d011F0214b3C85;
                                            }
                                        } else {
                                            if (routeId == 55) {
                                                return
                                                    0x9d70cDaCA12A738C283020760f449D7816D592ec;
                                            } else {
                                                return
                                                    0x95a23b9CB830EcCFDDD5dF56A4ec665e3381Fa12;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 61) {
                                        if (routeId < 59) {
                                            if (routeId == 57) {
                                                return
                                                    0x483a957Cf1251c20e096C35c8399721D1200A3Fc;
                                            } else {
                                                return
                                                    0xb4AD39Cb293b0Ec7FEDa743442769A7FF04987CD;
                                            }
                                        } else {
                                            if (routeId == 59) {
                                                return
                                                    0x4C543AD78c1590D81BAe09Fc5B6Df4132A2461d0;
                                            } else {
                                                return
                                                    0x471d5E5195c563902781734cfe1FF3981F8B6c86;
                                            }
                                        }
                                    } else {
                                        if (routeId < 63) {
                                            if (routeId == 61) {
                                                return
                                                    0x1B12a54B5E606D95B8B8D123c9Cb09221Ee37584;
                                            } else {
                                                return
                                                    0xE4127cC550baC433646a7D998775a84daC16c7f3;
                                            }
                                        } else {
                                            if (routeId == 63) {
                                                return
                                                    0xecb1b55AB12E7dd788D585c6C5cD61B5F87be836;
                                            } else {
                                                return
                                                    0xf91ef487C5A1579f70601b6D347e19756092eEBf;
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
                                                    0x34a16a7e9BADEEFD4f056310cbE0b1423Fa1b760;
                                            } else {
                                                return
                                                    0x60E10E80c7680f429dBbC232830BEcd3D623c4CF;
                                            }
                                        } else {
                                            if (routeId == 67) {
                                                return
                                                    0x66465285B8D65362A1d86CE00fE2bE949Fd6debF;
                                            } else {
                                                return
                                                    0x5aB231B7e1A3A74a48f67Ab7bde5Cdd4267022E0;
                                            }
                                        }
                                    } else {
                                        if (routeId < 71) {
                                            if (routeId == 69) {
                                                return
                                                    0x3A1C3633eE79d43366F5c67802a746aFD6b162Ba;
                                            } else {
                                                return
                                                    0x0C4BfCbA8dC3C811437521a80E81e41DAF479039;
                                            }
                                        } else {
                                            if (routeId == 71) {
                                                return
                                                    0x6caf25d2e139C5431a1FA526EAf8d73ff2e6252C;
                                            } else {
                                                return
                                                    0x74ad21e09FDa68638CE14A3009A79B6D16574257;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 77) {
                                        if (routeId < 75) {
                                            if (routeId == 73) {
                                                return
                                                    0xD4923A61008894b99cc1CD3407eF9524f02aA0Ca;
                                            } else {
                                                return
                                                    0x6F159b5EB823BD415886b9271aA2A723a00a1987;
                                            }
                                        } else {
                                            if (routeId == 75) {
                                                return
                                                    0x742a8aA42E7bfB4554dE30f4Fb07FFb6f2068863;
                                            } else {
                                                return
                                                    0x4AE9702d3360400E47B446e76DE063ACAb930101;
                                            }
                                        }
                                    } else {
                                        if (routeId < 79) {
                                            if (routeId == 77) {
                                                return
                                                    0x0E19a0a44ddA7dAD854ec5Cc867d16869c4E80F4;
                                            } else {
                                                return
                                                    0xE021A51968f25148F726E326C88d2556c5647557;
                                            }
                                        } else {
                                            if (routeId == 79) {
                                                return
                                                    0x64287BDDDaeF4d94E4599a3D882bed29E6Ada4B6;
                                            } else {
                                                return
                                                    0xcBB57Fd2e19cc7e9D444d5b4325A2F1047d0C73f;
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
                                                    0x373DE80DF7D82cFF6D76F29581b360C56331e957;
                                            } else {
                                                return
                                                    0x0466356E131AD61596a51F86BAd1C03A328960D8;
                                            }
                                        } else {
                                            if (routeId == 83) {
                                                return
                                                    0x01726B960992f1b74311b248E2a922fC707d43A6;
                                            } else {
                                                return
                                                    0x2E21bdf9A4509b89795BCE7E132f248a75814CEc;
                                            }
                                        }
                                    } else {
                                        if (routeId < 87) {
                                            if (routeId == 85) {
                                                return
                                                    0x769512b23aEfF842379091d3B6E4B5456F631D42;
                                            } else {
                                                return
                                                    0xe7eD9be946a74Ec19325D39C6EEb57887ccB2B0D;
                                            }
                                        } else {
                                            if (routeId == 87) {
                                                return
                                                    0xc4D01Ec357c2b511d10c15e6b6974380F0E62e67;
                                            } else {
                                                return
                                                    0x5bC49CC9dD77bECF2fd3A3C55611e84E69AFa3AE;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 93) {
                                        if (routeId < 91) {
                                            if (routeId == 89) {
                                                return
                                                    0x48bcD879954fA14e7DbdAeb56F79C1e9DDcb69ec;
                                            } else {
                                                return
                                                    0xE929bDde21b462572FcAA4de6F49B9D3246688D0;
                                            }
                                        } else {
                                            if (routeId == 91) {
                                                return
                                                    0x85Aae300438222f0e3A9Bc870267a5633A9438bd;
                                            } else {
                                                return
                                                    0x51f72E1096a81C55cd142d66d39B688C657f9Be8;
                                            }
                                        }
                                    } else {
                                        if (routeId < 95) {
                                            if (routeId == 93) {
                                                return
                                                    0x3A8a05BF68ac54B01E6C0f492abF97465F3d15f9;
                                            } else {
                                                return
                                                    0x145aA67133F0c2C36b9771e92e0B7655f0D59040;
                                            }
                                        } else {
                                            if (routeId == 95) {
                                                return
                                                    0xa030315d7DB11F9892758C9e7092D841e0ADC618;
                                            } else {
                                                return
                                                    0xdF1f8d81a3734bdDdEfaC6Ca1596E081e57c3044;
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
                                                    0xFF2833123B58aa05d04D7fb99f5FB768B2b435F8;
                                            } else {
                                                return
                                                    0xc8f09c1fD751C570233765f71b0e280d74e6e743;
                                            }
                                        } else {
                                            if (routeId == 99) {
                                                return
                                                    0x3026DA6Ceca2E5A57A05153653D9212FFAaA49d8;
                                            } else {
                                                return
                                                    0xdE68Ee703dE0D11f67B0cE5891cB4a903de6D160;
                                            }
                                        }
                                    } else {
                                        if (routeId < 103) {
                                            if (routeId == 101) {
                                                return
                                                    0xE23a7730e81FB4E87A6D0bd9f63EE77ac86C3DA4;
                                            } else {
                                                return
                                                    0x8b1DBe04aD76a7d8bC079cACd3ED4D99B897F4a0;
                                            }
                                        } else {
                                            if (routeId == 103) {
                                                return
                                                    0xBB227240FA459b69C6889B2b8cb1BE76F118061f;
                                            } else {
                                                return
                                                    0xC062b9b3f0dB28BB8afAfcD4d075729344114ffe;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 109) {
                                        if (routeId < 107) {
                                            if (routeId == 105) {
                                                return
                                                    0x553188Aa45f5FDB83EC4Ca485982F8fC082480D1;
                                            } else {
                                                return
                                                    0x0109d83D746EaCb6d4014953D9E12d6ca85e330b;
                                            }
                                        } else {
                                            if (routeId == 107) {
                                                return
                                                    0x45B1bEd29812F5bf6711074ACD180B2aeB783AD9;
                                            } else {
                                                return
                                                    0xdA06eC8c19aea31D77F60299678Cba40E743e1aD;
                                            }
                                        }
                                    } else {
                                        if (routeId < 111) {
                                            if (routeId == 109) {
                                                return
                                                    0x3cC5235c97d975a9b4FD4501B3446c981ea3D855;
                                            } else {
                                                return
                                                    0xa1827267d6Bd989Ff38580aE3d9deff6Acf19163;
                                            }
                                        } else {
                                            if (routeId == 111) {
                                                return
                                                    0x3663CAA0433A3D4171b3581Cf2410702840A735A;
                                            } else {
                                                return
                                                    0x7575D0a7614F655BA77C74a72a43bbd4fA6246a3;
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
                                                    0x2516Defc18bc07089c5dAFf5eafD7B0EF64611E2;
                                            } else {
                                                return
                                                    0xfec5FF08E20fbc107a97Af2D38BD0025b84ee233;
                                            }
                                        } else {
                                            if (routeId == 115) {
                                                return
                                                    0x0FB5763a87242B25243e23D73f55945fE787523A;
                                            } else {
                                                return
                                                    0xe4C00db89678dBf8391f430C578Ca857Dd98aDE1;
                                            }
                                        }
                                    } else {
                                        if (routeId < 119) {
                                            if (routeId == 117) {
                                                return
                                                    0x8F2A22061F9F35E64f14523dC1A5f8159e6a21B7;
                                            } else {
                                                return
                                                    0x18e4b838ae966917E20E9c9c5Ad359cDD38303bB;
                                            }
                                        } else {
                                            if (routeId == 119) {
                                                return
                                                    0x61ACb1d3Dcb3e3429832A164Cc0fC9849fb75A4a;
                                            } else {
                                                return
                                                    0x7681e3c8e7A41DCA55C257cc0d1Ae757f5530E65;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 125) {
                                        if (routeId < 123) {
                                            if (routeId == 121) {
                                                return
                                                    0x806a2AB9748C3D1DB976550890E3f528B7E8Faec;
                                            } else {
                                                return
                                                    0xBDb8A5DD52C2c239fbC31E9d43B763B0197028FF;
                                            }
                                        } else {
                                            if (routeId == 123) {
                                                return
                                                    0x474EC9203706010B9978D6bD0b105D36755e4848;
                                            } else {
                                                return
                                                    0x8dfd0D829b303F2239212E591a0F92a32880f36E;
                                            }
                                        }
                                    } else {
                                        if (routeId < 127) {
                                            if (routeId == 125) {
                                                return
                                                    0xad4BcE9745860B1adD6F1Bd34a916f050E4c82C2;
                                            } else {
                                                return
                                                    0xBC701115b9fe14bC8CC5934cdC92517173e308C4;
                                            }
                                        } else {
                                            if (routeId == 127) {
                                                return
                                                    0x0D1918d786Db8546a11aDeD475C98370E06f255E;
                                            } else {
                                                return
                                                    0xee44f57cD6936DB55B99163f3Df367B01EdA785a;
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
                                                    0x63044521fe5a1e488D7eD419cD0e35b7C24F2aa7;
                                            } else {
                                                return
                                                    0x410085E73BD85e90d97b84A68C125aDB9F91f85b;
                                            }
                                        } else {
                                            if (routeId == 131) {
                                                return
                                                    0x7913fe97E07C7A397Ec274Ab1d4E2622C88EC5D1;
                                            } else {
                                                return
                                                    0x977f9fE93c064DCf54157406DaABC3a722e8184C;
                                            }
                                        }
                                    } else {
                                        if (routeId < 135) {
                                            if (routeId == 133) {
                                                return
                                                    0xCD2236468722057cFbbABad2db3DEA9c20d5B01B;
                                            } else {
                                                return
                                                    0x17c7287A491cf5Ff81E2678cF2BfAE4333F6108c;
                                            }
                                        } else {
                                            if (routeId == 135) {
                                                return
                                                    0x354D9a5Dbf96c71B79a265F03B595C6Fdc04dadd;
                                            } else {
                                                return
                                                    0xb4e409EB8e775eeFEb0344f9eee884cc7ed21c69;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 141) {
                                        if (routeId < 139) {
                                            if (routeId == 137) {
                                                return
                                                    0xa1a3c4670Ad69D9be4ab2D39D1231FEC2a63b519;
                                            } else {
                                                return
                                                    0x4589A22199870729C1be5CD62EE93BeD858113E6;
                                            }
                                        } else {
                                            if (routeId == 139) {
                                                return
                                                    0x8E7b864dB26Bd6C798C38d4Ba36EbA0d6602cF11;
                                            } else {
                                                return
                                                    0xA2D17C7260a4CB7b9854e89Fc367E80E87872a2d;
                                            }
                                        }
                                    } else {
                                        if (routeId < 143) {
                                            if (routeId == 141) {
                                                return
                                                    0xC7F0EDf0A1288627b0432304918A75e9084CBD46;
                                            } else {
                                                return
                                                    0xE4B4EF1f9A4aBFEdB371fA7a6143993B15d4df25;
                                            }
                                        } else {
                                            if (routeId == 143) {
                                                return
                                                    0xfe3D84A2Ef306FEBb5452441C9BDBb6521666F6A;
                                            } else {
                                                return
                                                    0x8A12B6C64121920110aE58F7cd67DfEc21c6a4C3;
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
                                                    0x76c4d9aFC4717a2BAac4e5f26CccF02351f7a3DA;
                                            } else {
                                                return
                                                    0xd4719BA550E397aeAcca1Ad2201c1ba69024FAAf;
                                            }
                                        } else {
                                            if (routeId == 147) {
                                                return
                                                    0x9646126Ce025224d1682C227d915a386efc0A1Fb;
                                            } else {
                                                return
                                                    0x4DD8Af2E3F2044842f0247920Bc4BABb636915ea;
                                            }
                                        }
                                    } else {
                                        if (routeId < 151) {
                                            if (routeId == 149) {
                                                return
                                                    0x8e8a327183Af0cf8C2ece9F0ed547C42A160D409;
                                            } else {
                                                return
                                                    0x9D49614CaE1C685C71678CA6d8CDF7584bfd0740;
                                            }
                                        } else {
                                            if (routeId == 151) {
                                                return
                                                    0x5a00ef257394cbc31828d48655E3d39e9c11c93d;
                                            } else {
                                                return
                                                    0xC9a2751b38d3dDD161A41Ca0135C5C6c09EC1d56;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 157) {
                                        if (routeId < 155) {
                                            if (routeId == 153) {
                                                return
                                                    0x7e1c261640a525C94Ca4f8c25b48CF754DD83590;
                                            } else {
                                                return
                                                    0x409Fe24ba6F6BD5aF31C1aAf8059b986A3158233;
                                            }
                                        } else {
                                            if (routeId == 155) {
                                                return
                                                    0x704Cf5BFDADc0f55fDBb53B6ed8B582E018A72A2;
                                            } else {
                                                return
                                                    0x3982bF65d7d6E77E3b6661cd6F6468c247512737;
                                            }
                                        }
                                    } else {
                                        if (routeId < 159) {
                                            if (routeId == 157) {
                                                return
                                                    0x3982b9f26FFD67a13Ee371e2C0a9Da338BA70E7f;
                                            } else {
                                                return
                                                    0x6D834AB385900c1f49055D098e90264077FbC4f2;
                                            }
                                        } else {
                                            if (routeId == 159) {
                                                return
                                                    0x11FE5F70779A094B7166B391e1Fb73d422eF4e4d;
                                            } else {
                                                return
                                                    0xD347e4E47280d21F13B73D89c6d16f867D50DD13;
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
                                                    0xb6035eDD53DDA28d8B69b4ae9836E40C80306CD7;
                                            } else {
                                                return
                                                    0x54c884e6f5C7CcfeCA990396c520C858c922b6CA;
                                            }
                                        } else {
                                            if (routeId == 163) {
                                                return
                                                    0x5eA93E240b083d686558Ed607BC013d88057cE46;
                                            } else {
                                                return
                                                    0x4C7131eE812De685cBe4e2cCb033d46ecD46612E;
                                            }
                                        }
                                    } else {
                                        if (routeId < 167) {
                                            if (routeId == 165) {
                                                return
                                                    0xc1a5Be9F0c33D8483801D702111068669f81fF91;
                                            } else {
                                                return
                                                    0x9E5fAb91455Be5E5b2C05967E73F456c8118B1Fc;
                                            }
                                        } else {
                                            if (routeId == 167) {
                                                return
                                                    0x3d9A05927223E0DC2F382831770405885e22F0d8;
                                            } else {
                                                return
                                                    0x6303A011fB6063f5B1681cb5a9938EA278dc6128;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 173) {
                                        if (routeId < 171) {
                                            if (routeId == 169) {
                                                return
                                                    0xe9c60795c90C66797e4c8E97511eA07CdAda32bE;
                                            } else {
                                                return
                                                    0xD56cC98e69A1e13815818b466a8aA6163d84234A;
                                            }
                                        } else {
                                            if (routeId == 171) {
                                                return
                                                    0x47EbB9D36a6e40895316cD894E4860D774E2c531;
                                            } else {
                                                return
                                                    0xA5EB293629410065d14a7B1663A67829b0618292;
                                            }
                                        }
                                    } else {
                                        if (routeId < 175) {
                                            if (routeId == 173) {
                                                return
                                                    0x1b3B4C8146F939cE00899db8B3ddeF0062b7E023;
                                            } else {
                                                return
                                                    0x257Bbc11653625EbfB6A8587eF4f4FBe49828EB3;
                                            }
                                        } else {
                                            if (routeId == 175) {
                                                return
                                                    0x44cc979C01b5bB1eAC21301E73C37200dFD06F59;
                                            } else {
                                                return
                                                    0x2972fDF43352225D82754C0174Ff853819D1ef2A;
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
                                                    0x3e54144f032648A04D62d79f7B4b93FF3aC2333b;
                                            } else {
                                                return
                                                    0x444016102dB8adbE73C3B6703a1ea7F2f75A510D;
                                            }
                                        } else {
                                            if (routeId == 179) {
                                                return
                                                    0xac079143f98a6eb744Fde34541ebF243DF5B5dED;
                                            } else {
                                                return
                                                    0xAe9010767Fb112d29d35CEdfba2b372Ad7A308d3;
                                            }
                                        }
                                    } else {
                                        if (routeId < 183) {
                                            if (routeId == 181) {
                                                return
                                                    0xfE0BCcF9cCC2265D5fB3450743f17DfE57aE1e56;
                                            } else {
                                                return
                                                    0x04ED8C0545716119437a45386B1d691C63234C7D;
                                            }
                                        } else {
                                            if (routeId == 183) {
                                                return
                                                    0x636c14013e531A286Bc4C848da34585f0bB73d59;
                                            } else {
                                                return
                                                    0x2Fa67fc7ECC5cAA01C653d3BFeA98ecc5db9C42A;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 189) {
                                        if (routeId < 187) {
                                            if (routeId == 185) {
                                                return
                                                    0x23e9a0FC180818aA872D2079a985217017E97bd9;
                                            } else {
                                                return
                                                    0x79A95c3Ef81b3ae64ee03A9D5f73e570495F164E;
                                            }
                                        } else {
                                            if (routeId == 187) {
                                                return
                                                    0xa7EA0E88F04a84ba0ad1E396cb07Fa3fDAD7dF6D;
                                            } else {
                                                return
                                                    0xd23cA1278a2B01a3C0Ca1a00d104b11c1Ebe6f42;
                                            }
                                        }
                                    } else {
                                        if (routeId < 191) {
                                            if (routeId == 189) {
                                                return
                                                    0x707bc4a9FA2E349AED5df4e9f5440C15aA9D14Bd;
                                            } else {
                                                return
                                                    0x7E290F2dd539Ac6CE58d8B4C2B944931a1fD3612;
                                            }
                                        } else {
                                            if (routeId == 191) {
                                                return
                                                    0x707AA5503088Ce06Ba450B6470A506122eA5c8eF;
                                            } else {
                                                return
                                                    0xFbB3f7BF680deeb149f4E7BC30eA3DDfa68F3C3f;
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
                                                    0xDE74aD8cCC3dbF14992f49Cf24f36855912f4934;
                                            } else {
                                                return
                                                    0x409BA83df7777F070b2B50a10a41DE2468d2a3B3;
                                            }
                                        } else {
                                            if (routeId == 195) {
                                                return
                                                    0x5CB7Be90A5DD7CfDa54e87626e254FE8C18255B4;
                                            } else {
                                                return
                                                    0x0A684fE12BC64fb72B59d0771a566F49BC090356;
                                            }
                                        }
                                    } else {
                                        if (routeId < 199) {
                                            if (routeId == 197) {
                                                return
                                                    0xDf30048d91F8FA2bCfC54952B92bFA8e161D3360;
                                            } else {
                                                return
                                                    0x050825Fff032a547C47061CF0696FDB0f65AEa5D;
                                            }
                                        } else {
                                            if (routeId == 199) {
                                                return
                                                    0xd55e671dAC1f03d366d8535073ada5DB2Aab1Ea2;
                                            } else {
                                                return
                                                    0x9470C704A9616c8Cd41c595Fcd2181B6fe2183C2;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 205) {
                                        if (routeId < 203) {
                                            if (routeId == 201) {
                                                return
                                                    0x2D9ffD275181F5865d5e11CbB4ced1521C4dF9f1;
                                            } else {
                                                return
                                                    0x816d28Dec10ec95DF5334f884dE85cA6215918d8;
                                            }
                                        } else {
                                            if (routeId == 203) {
                                                return
                                                    0xd1f87267c4A43835E666dd69Df077e578A3b6299;
                                            } else {
                                                return
                                                    0x39E89Bde9DACbe5468C025dE371FbDa12bDeBAB1;
                                            }
                                        }
                                    } else {
                                        if (routeId < 207) {
                                            if (routeId == 205) {
                                                return
                                                    0x7b40A3207956ecad6686E61EfcaC48912FcD0658;
                                            } else {
                                                return
                                                    0x090cF10D793B1Efba9c7D76115878814B663859A;
                                            }
                                        } else {
                                            if (routeId == 207) {
                                                return
                                                    0x312A59c06E41327878F2063eD0e9c282C1DA3AfC;
                                            } else {
                                                return
                                                    0x4F1188f46236DD6B5de11Ebf2a9fF08716E7DeB6;
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
                                                    0x0A6F9a3f4fA49909bBfb4339cbE12B42F53BbBeD;
                                            } else {
                                                return
                                                    0x01d13d7aCaCbB955B81935c80ffF31e14BdFa71f;
                                            }
                                        } else {
                                            if (routeId == 211) {
                                                return
                                                    0x691a14Fa6C7360422EC56dF5876f84d4eDD7f00A;
                                            } else {
                                                return
                                                    0x97Aad18d886d181a9c726B3B6aE15a0A69F5aF73;
                                            }
                                        }
                                    } else {
                                        if (routeId < 215) {
                                            if (routeId == 213) {
                                                return
                                                    0x2917241371D2099049Fa29432DC46735baEC33b4;
                                            } else {
                                                return
                                                    0x5F20F20F7890c2e383E29D4147C9695A371165f5;
                                            }
                                        } else {
                                            if (routeId == 215) {
                                                return
                                                    0xeC0a60e639958335662C5219A320cCEbb56C6077;
                                            } else {
                                                return
                                                    0x96d63CF5062975C09845d17ec672E10255866053;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 221) {
                                        if (routeId < 219) {
                                            if (routeId == 217) {
                                                return
                                                    0xFF57429e57D383939CAB50f09ABBfB63C0e6c9AD;
                                            } else {
                                                return
                                                    0x18E393A7c8578fb1e235C242076E50013cDdD0d7;
                                            }
                                        } else {
                                            if (routeId == 219) {
                                                return
                                                    0xE7E5238AF5d61f52E9B4ACC025F713d1C0216507;
                                            } else {
                                                return
                                                    0x428401D4d0F25A2EE1DA4d5366cB96Ded425D9bD;
                                            }
                                        }
                                    } else {
                                        if (routeId < 223) {
                                            if (routeId == 221) {
                                                return
                                                    0x42E5733551ff1Ee5B48Aa9fc2B61Af9b58C812E6;
                                            } else {
                                                return
                                                    0x64Df9c7A0551B056d860Bc2419Ca4c1EF75320bE;
                                            }
                                        } else {
                                            if (routeId == 223) {
                                                return
                                                    0x46006925506145611bBf0263243D8627dAf26B0F;
                                            } else {
                                                return
                                                    0x8D64BE884314662804eAaB884531f5C50F4d500c;
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
                                                    0x157a62D92D07B5ce221A5429645a03bBaCE85373;
                                            } else {
                                                return
                                                    0xaF037D33e1F1F2F87309B425fe8a9d895Ef3722B;
                                            }
                                        } else {
                                            if (routeId == 227) {
                                                return
                                                    0x921D1154E494A2f7218a37ad7B17701f94b4B40e;
                                            } else {
                                                return
                                                    0xF282b4555186d8Dea51B8b3F947E1E0568d09bc4;
                                            }
                                        }
                                    } else {
                                        if (routeId < 231) {
                                            if (routeId == 229) {
                                                return
                                                    0xa794E2E1869765a4600b3DFd8a4ebcF16350f6B6;
                                            } else {
                                                return
                                                    0xFEFb048e20c5652F7940A49B1980E0125Ec4D358;
                                            }
                                        } else {
                                            if (routeId == 231) {
                                                return
                                                    0x220104b641971e9b25612a8F001bf48AbB23f1cF;
                                            } else {
                                                return
                                                    0xcB9D373Bb54A501B35dd3be5bF4Ba43cA31F7035;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 237) {
                                        if (routeId < 235) {
                                            if (routeId == 233) {
                                                return
                                                    0x37D627F56e3FF36aC316372109ea82E03ac97DAc;
                                            } else {
                                                return
                                                    0x4E81355FfB4A271B4EA59ff78da2b61c7833161f;
                                            }
                                        } else {
                                            if (routeId == 235) {
                                                return
                                                    0xADd8D65cAF6Cc9ad73127B49E16eA7ac29d91e87;
                                            } else {
                                                return
                                                    0x630F9b95626487dfEAe3C97A44DB6C59cF35d996;
                                            }
                                        }
                                    } else {
                                        if (routeId < 239) {
                                            if (routeId == 237) {
                                                return
                                                    0x78CE2BC8238B679680A67FCB98C5A60E4ec17b2D;
                                            } else {
                                                return
                                                    0xA38D776028eD1310b9A6b086f67F788201762E21;
                                            }
                                        } else {
                                            if (routeId == 239) {
                                                return
                                                    0x7Bb5178827B76B86753Ed62a0d662c72cEcb1bD3;
                                            } else {
                                                return
                                                    0x4faC26f61C76eC5c3D43b43eDfAFF0736Ae0e3da;
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
                                                    0x791Bb49bfFA7129D6889FDB27744422Ac4571A85;
                                            } else {
                                                return
                                                    0x26766fFEbb5fa564777913A6f101dF019AB32afa;
                                            }
                                        } else {
                                            if (routeId == 243) {
                                                return
                                                    0x05e98E5e95b4ECBbbAf3258c3999Cc81ed8048Be;
                                            } else {
                                                return
                                                    0xC5c4621e52f1D6A1825A5ed4F95855401a3D9C6b;
                                            }
                                        }
                                    } else {
                                        if (routeId < 247) {
                                            if (routeId == 245) {
                                                return
                                                    0xfcb15f909BA7FC7Ea083503Fb4c1020203c107EB;
                                            } else {
                                                return
                                                    0xbD27603279d969c74f2486ad14E71080829DFd38;
                                            }
                                        } else {
                                            if (routeId == 247) {
                                                return
                                                    0xff2f756BcEcC1A55BFc09a30cc5F64720458cFCB;
                                            } else {
                                                return
                                                    0x3bfB968FEbC12F4e8420B2d016EfcE1E615f7246;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 253) {
                                        if (routeId < 251) {
                                            if (routeId == 249) {
                                                return
                                                    0x982EE9Ffe23051A2ec945ed676D864fa8345222b;
                                            } else {
                                                return
                                                    0xe101899100785E74767d454FFF0131277BaD48d9;
                                            }
                                        } else {
                                            if (routeId == 251) {
                                                return
                                                    0x4F730C0c6b3B5B7d06ca511379f4Aa5BfB2E9525;
                                            } else {
                                                return
                                                    0x5499c36b365795e4e0Ef671aF6C2ce26D7c78265;
                                            }
                                        }
                                    } else {
                                        if (routeId < 255) {
                                            if (routeId == 253) {
                                                return
                                                    0x8AF51F7237Fc8fB2fc3E700488a94a0aC6Ad8b5a;
                                            } else {
                                                return
                                                    0xda8716df61213c0b143F2849785FB85928084857;
                                            }
                                        } else {
                                            if (routeId == 255) {
                                                return
                                                    0xF040Cf9b1ebD11Bf28e04e80740DF3DDe717e4f5;
                                            } else {
                                                return
                                                    0xB87ba32f759D14023C7520366B844dF7f0F036C2;
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
                                                0x0Edde681b8478F0c3194f468EdD2dB5e75c65CDD;
                                        } else {
                                            return
                                                0x59C70900Fca06eE2aCE1BDd5A8D0Af0cc3BBA720;
                                        }
                                    } else {
                                        if (routeId == 259) {
                                            return
                                                0x8041F0f180D17dD07087199632c45E17AeB0BAd5;
                                        } else {
                                            return
                                                0x4fB4727064BA595995DD516b63b5921Df9B93aC6;
                                        }
                                    }
                                } else {
                                    if (routeId < 263) {
                                        if (routeId == 261) {
                                            return
                                                0x86e98b594565857eD098864F560915C0dAfd6Ea1;
                                        } else {
                                            return
                                                0x70f8818E8B698EFfeCd86A513a4c87c0c380Bef6;
                                        }
                                    } else {
                                        if (routeId == 263) {
                                            return
                                                0x78Ed227c8A897A21Da2875a752142dd80d865158;
                                        } else {
                                            return
                                                0xd02A30BB5C3a8C51d2751A029a6fcfDE2Af9fbc6;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 269) {
                                    if (routeId < 267) {
                                        if (routeId == 265) {
                                            return
                                                0x0F00d5c5acb24e975e2a56730609f7F40aa763b8;
                                        } else {
                                            return
                                                0xC3e2091edc2D3D9D98ba09269138b617B536834A;
                                        }
                                    } else {
                                        if (routeId == 267) {
                                            return
                                                0xa6FbaF7F30867C9633908998ea8C3da28920E75C;
                                        } else {
                                            return
                                                0xE6dDdcD41E2bBe8122AE32Ac29B8fbAB79CD21d9;
                                        }
                                    }
                                } else {
                                    if (routeId < 271) {
                                        if (routeId == 269) {
                                            return
                                                0x537aa8c1Ef6a8Eaf039dd6e1Eb67694a48195cE4;
                                        } else {
                                            return
                                                0x96ABAC485fd2D0B03CF4a10df8BD58b8dED28300;
                                        }
                                    } else {
                                        if (routeId == 271) {
                                            return
                                                0xda8e7D46d04Bd4F62705Cd80355BDB6d441DafFD;
                                        } else {
                                            return
                                                0xbE50018E7a5c67E2e5f5414393e971CC96F293f2;
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
                                                0xa1b3907D6CB542a4cbe2eE441EfFAA909FAb62C3;
                                        } else {
                                            return
                                                0x6d08ee8511C0237a515013aC389e7B3968Cb1753;
                                        }
                                    } else {
                                        if (routeId == 275) {
                                            return
                                                0x22faa5B5Fe43eAdbB52745e35a5cdA8bD5F96bbA;
                                        } else {
                                            return
                                                0x7a673eB74D79e4868D689E7852abB5f93Ec2fD4b;
                                        }
                                    }
                                } else {
                                    if (routeId < 279) {
                                        if (routeId == 277) {
                                            return
                                                0x0b8531F8AFD4190b76F3e10deCaDb84c98b4d419;
                                        } else {
                                            return
                                                0x78eABC743A93583DeE403D6b84795490e652216B;
                                        }
                                    } else {
                                        if (routeId == 279) {
                                            return
                                                0x3A95D907b2a7a8604B59BccA08585F58Afe0Aa64;
                                        } else {
                                            return
                                                0xf4271f0C8c9Af0F06A80b8832fa820ccE64FAda8;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 285) {
                                    if (routeId < 283) {
                                        if (routeId == 281) {
                                            return
                                                0x74b2DF841245C3748c0d31542e1335659a25C33b;
                                        } else {
                                            return
                                                0xdFC99Fd0Ad7D16f30f295a5EEFcE029E04d0fa65;
                                        }
                                    } else {
                                        if (routeId == 283) {
                                            return
                                                0xE992416b6aC1144eD8148a9632973257839027F6;
                                        } else {
                                            return
                                                0x54ce55ba954E981BB1fd9399054B35Ce1f2C0816;
                                        }
                                    }
                                } else {
                                    if (routeId < 287) {
                                        if (routeId == 285) {
                                            return
                                                0xD4AB52f9e7E5B315Bd7471920baD04F405Ab1c38;
                                        } else {
                                            return
                                                0x3670C990994d12837e95eE127fE2f06FD3E2104B;
                                        }
                                    } else {
                                        if (routeId == 287) {
                                            return
                                                0xDcf190B09C47E4f551E30BBb79969c3FdEA1e992;
                                        } else {
                                            return
                                                0xa65057B967B59677237e57Ab815B209744b9bc40;
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
                                                0x6Efc86B40573e4C7F28659B13327D55ae955C483;
                                        } else {
                                            return
                                                0x06BcC25CF8e0E72316F53631b3aA7134E9f73Ae0;
                                        }
                                    } else {
                                        if (routeId == 291) {
                                            return
                                                0x710b6414E1D53882b1FCD3A168aD5Ccd435fc6D0;
                                        } else {
                                            return
                                                0x5Ebb2C3d78c4e9818074559e7BaE7FCc99781DC1;
                                        }
                                    }
                                } else {
                                    if (routeId < 295) {
                                        if (routeId == 293) {
                                            return
                                                0xAf0a409c3AEe0bD08015cfb29D89E90b6e89A88F;
                                        } else {
                                            return
                                                0x522559d8b99773C693B80cE06DF559036295Ce44;
                                        }
                                    } else {
                                        if (routeId == 295) {
                                            return
                                                0xB65290A5Bae838aaa7825c9ECEC68041841a1B64;
                                        } else {
                                            return
                                                0x801b8F2068edd5Bcb659E6BDa0c425909043C420;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 301) {
                                    if (routeId < 299) {
                                        if (routeId == 297) {
                                            return
                                                0x29b5F00515d093627E0B7bd0b5c8E84F6b4cDb87;
                                        } else {
                                            return
                                                0x652839Ae74683cbF9f1293F1019D938F87464D3E;
                                        }
                                    } else {
                                        if (routeId == 299) {
                                            return
                                                0x5Bc95dCebDDE9B79F2b6DC76121BC7936eF8D666;
                                        } else {
                                            return
                                                0x90db359CEA62E53051158Ab5F99811C0a07Fe686;
                                        }
                                    }
                                } else {
                                    if (routeId < 303) {
                                        if (routeId == 301) {
                                            return
                                                0x2c3625EedadbDcDbB5330eb0d17b3C39ff269807;
                                        } else {
                                            return
                                                0xC3f0324471b5c9d415acD625b8d8694a4e48e001;
                                        }
                                    } else {
                                        if (routeId == 303) {
                                            return
                                                0x8C60e7E05fa0FfB6F720233736f245134685799d;
                                        } else {
                                            return
                                                0x98fAF2c09aa4EBb995ad0B56152993E7291a500e;
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
                                                0x802c1063a861414dFAEc16bacb81429FC0d40D6e;
                                        } else {
                                            return
                                                0x11C4AeFCC0dC156f64195f6513CB1Fb3Be0Ae056;
                                        }
                                    } else {
                                        if (routeId == 307) {
                                            return
                                                0xEff1F3258214E31B6B4F640b4389d55715C3Be2B;
                                        } else {
                                            return
                                                0x47e379Abe8DDFEA4289aBa01235EFF7E93758fd7;
                                        }
                                    }
                                } else {
                                    if (routeId < 311) {
                                        if (routeId == 309) {
                                            return
                                                0x3CC26384c3eA31dDc8D9789e8872CeA6F20cD3ff;
                                        } else {
                                            return
                                                0xEdd9EFa6c69108FAA4611097d643E20Ba0Ed1634;
                                        }
                                    } else {
                                        if (routeId == 311) {
                                            return
                                                0xCb93525CA5f3D371F74F3D112bC19526740717B8;
                                        } else {
                                            return
                                                0x7071E0124EB4438137e60dF1b8DD8Af1BfB362cF;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 317) {
                                    if (routeId < 315) {
                                        if (routeId == 313) {
                                            return
                                                0x4691096EB0b78C8F4b4A8091E5B66b18e1835c10;
                                        } else {
                                            return
                                                0x8d953c9b2d1C2137CF95992079f3A77fCd793272;
                                        }
                                    } else {
                                        if (routeId == 315) {
                                            return
                                                0xbdCc2A3Bf6e3Ba49ff86595e6b2b8D70d8368c92;
                                        } else {
                                            return
                                                0x95E6948aB38c61b2D294E8Bd896BCc4cCC0713cf;
                                        }
                                    }
                                } else {
                                    if (routeId < 319) {
                                        if (routeId == 317) {
                                            return
                                                0x607b27C881fFEE4Cb95B1c5862FaE7224ccd0b4A;
                                        } else {
                                            return
                                                0x09D28aFA166e566A2Ee1cB834ea8e78C7E627eD2;
                                        }
                                    } else {
                                        if (routeId == 319) {
                                            return
                                                0x9c01449b38bDF0B263818401044Fb1401B29fDfA;
                                        } else {
                                            return
                                                0x1F7723599bbB658c051F8A39bE2688388d22ceD6;
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
                                                0x52B71603f7b8A5d15B4482e965a0619aa3210194;
                                        } else {
                                            return
                                                0x01c0f072CB210406653752FecFA70B42dA9173a2;
                                        }
                                    } else {
                                        if (routeId == 323) {
                                            return
                                                0x3021142f021E943e57fc1886cAF58D06147D09A6;
                                        } else {
                                            return
                                                0xe6f2AF38e76AB09Db59225d97d3E770942D3D842;
                                        }
                                    }
                                } else {
                                    if (routeId < 327) {
                                        if (routeId == 325) {
                                            return
                                                0x06a25554e5135F08b9e2eD1DEC1fc3CEd52e0B48;
                                        } else {
                                            return
                                                0x71d75e670EE3511C8290C705E0620126B710BF8D;
                                        }
                                    } else {
                                        if (routeId == 327) {
                                            return
                                                0x8b9cE142b80FeA7c932952EC533694b1DF9B3c54;
                                        } else {
                                            return
                                                0xd7Be24f32f39231116B3fDc483C2A12E1521f73B;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 333) {
                                    if (routeId < 331) {
                                        if (routeId == 329) {
                                            return
                                                0xb40cafBC4797d4Ff64087E087F6D2e661f954CbE;
                                        } else {
                                            return
                                                0xBdDCe7771EfEe81893e838f62204A4c76D72757e;
                                        }
                                    } else {
                                        if (routeId == 331) {
                                            return
                                                0x5d3D299EA7Fd4F39AcDb336E26631Dfee41F9287;
                                        } else {
                                            return
                                                0x6BfEE09E1Fc0684e0826A9A0dC1352a14B136FAC;
                                        }
                                    }
                                } else {
                                    if (routeId < 335) {
                                        if (routeId == 333) {
                                            return
                                                0xd0001bB8E2Cb661436093f96458a4358B5156E3c;
                                        } else {
                                            return
                                                0x1867c6485CfD1eD448988368A22bfB17a7747293;
                                        }
                                    } else {
                                        if (routeId == 335) {
                                            return
                                                0x8997EF9F95dF24aB67703AB6C262aABfeEBE33bD;
                                        } else {
                                            return
                                                0x1e39E9E601922deD91BCFc8F78836302133465e2;
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
                                                0x8A8ec6CeacFf502a782216774E5AF3421562C6ff;
                                        } else {
                                            return
                                                0x3B8FC561df5415c8DC01e97Ee6E38435A8F9C40A;
                                        }
                                    } else {
                                        if (routeId == 339) {
                                            return
                                                0xD5d5f5B37E67c43ceA663aEDADFFc3a93a2065B0;
                                        } else {
                                            return
                                                0xCC8F55EC43B4f25013CE1946FBB740c43Be5B96D;
                                        }
                                    }
                                } else {
                                    if (routeId < 343) {
                                        if (routeId == 341) {
                                            return
                                                0x18f586E816eEeDbb57B8011239150367561B58Fb;
                                        } else {
                                            return
                                                0xd0CD802B19c1a52501cb2f07d656e3Cd7B0Ce124;
                                        }
                                    } else {
                                        if (routeId == 343) {
                                            return
                                                0xe0AeD899b39C6e4f2d83e4913a1e9e0cf6368abE;
                                        } else {
                                            return
                                                0x0606e1b6c0f1A398C38825DCcc4678a7Cbc2737c;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 349) {
                                    if (routeId < 347) {
                                        if (routeId == 345) {
                                            return
                                                0x2d188e85b27d18EF80f16686EA1593ABF7Ed2A63;
                                        } else {
                                            return
                                                0x64412292fA4A135a3300E24366E99ff59Db2eAc1;
                                        }
                                    } else {
                                        if (routeId == 347) {
                                            return
                                                0x38b74c173f3733E8b90aAEf0e98B89791266149F;
                                        } else {
                                            return
                                                0x36DAA49A79aaEF4E7a217A11530D3cCD84414124;
                                        }
                                    }
                                } else {
                                    if (routeId < 351) {
                                        if (routeId == 349) {
                                            return
                                                0x10f088FE2C88F90270E4449c46c8B1b232511d58;
                                        } else {
                                            return
                                                0x4FeDbd25B58586838ABD17D10272697dF1dC3087;
                                        }
                                    } else {
                                        if (routeId == 351) {
                                            return
                                                0x685278209248CB058E5cEe93e37f274A80Faf6eb;
                                        } else {
                                            return
                                                0xDd9F8F1eeC3955f78168e2Fb2d1e808fa8A8f15b;
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
                                                0x7392aEeFD5825aaC28817031dEEBbFaAA20983D9;
                                        } else {
                                            return
                                                0x0Cc182555E00767D6FB8AD161A10d0C04C476d91;
                                        }
                                    } else {
                                        if (routeId == 355) {
                                            return
                                                0x90E52837d56715c79FD592E8D58bFD20365798b2;
                                        } else {
                                            return
                                                0x6F4451DE14049B6770ad5BF4013118529e68A40C;
                                        }
                                    }
                                } else {
                                    if (routeId < 359) {
                                        if (routeId == 357) {
                                            return
                                                0x89B97ef2aFAb9ed9c7f0FDb095d02E6840b52d9c;
                                        } else {
                                            return
                                                0x92A5cC5C42d94d3e23aeB1214fFf43Db2B97759E;
                                        }
                                    } else {
                                        if (routeId == 359) {
                                            return
                                                0x63ddc52F135A1dcBA831EAaC11C63849F018b739;
                                        } else {
                                            return
                                                0x692A691533B571C2c54C1D7F8043A204b3d8120E;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 365) {
                                    if (routeId < 363) {
                                        if (routeId == 361) {
                                            return
                                                0x97c7492CF083969F61C6f302d45c8270391b921c;
                                        } else {
                                            return
                                                0xDeFD2B8643553dAd19548eB14fd94A57F4B9e543;
                                        }
                                    } else {
                                        if (routeId == 363) {
                                            return
                                                0x30645C04205cA3f670B67b02F971B088930ACB8C;
                                        } else {
                                            return
                                                0xA6f80ed2d607Cd67aEB4109B64A0BEcc4D7d03CF;
                                        }
                                    }
                                } else {
                                    if (routeId < 367) {
                                        if (routeId == 365) {
                                            return
                                                0xBbbbC6c276eB3F7E674f2D39301509236001c42f;
                                        } else {
                                            return
                                                0xC20E77d349FB40CE88eB01824e2873ad9f681f3C;
                                        }
                                    } else {
                                        if (routeId == 367) {
                                            return
                                                0x5fCfD9a962De19294467C358C1FA55082285960b;
                                        } else {
                                            return
                                                0x4D87BD6a0E4E5cc6332923cb3E85fC71b287F58A;
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
                                                0x3AA5B757cd6Dde98214E56D57Dde7fcF0F7aB04E;
                                        } else {
                                            return
                                                0xe28eFCE7192e11a2297f44059113C1fD6967b2d4;
                                        }
                                    } else {
                                        if (routeId == 371) {
                                            return
                                                0x3251cAE10a1Cf246e0808D76ACC26F7B5edA0eE5;
                                        } else {
                                            return
                                                0xbA2091cc9357Cf4c4F25D64F30d1b4Ba3A5a174B;
                                        }
                                    }
                                } else {
                                    if (routeId < 375) {
                                        if (routeId == 373) {
                                            return
                                                0x49c8e1Da9693692096F63C82D11b52d738566d55;
                                        } else {
                                            return
                                                0xA0731615aB5FFF451031E9551367A4F7dB27b39c;
                                        }
                                    } else {
                                        if (routeId == 375) {
                                            return
                                                0xFb214541888671AE1403CecC1D59763a12fc1609;
                                        } else {
                                            return
                                                0x1D6bCB17642E2336405df73dF22F07688cAec020;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 381) {
                                    if (routeId < 379) {
                                        if (routeId == 377) {
                                            return
                                                0xfC9c0C7bfe187120fF7f4E21446161794A617a9e;
                                        } else {
                                            return
                                                0xBa5bF37678EeE2dAB17AEf9D898153258252250E;
                                        }
                                    } else {
                                        if (routeId == 379) {
                                            return
                                                0x7c55690bd2C9961576A32c02f8EB29ed36415Ec7;
                                        } else {
                                            return
                                                0xcA40073E868E8Bc611aEc8Fe741D17E68Fe422f6;
                                        }
                                    }
                                } else {
                                    if (routeId < 383) {
                                        if (routeId == 381) {
                                            return
                                                0x31641bAFb87E9A58f78835050a7BE56921986339;
                                        } else {
                                            return
                                                0xA54766424f6dA74b45EbCc5Bf0Bd1D74D2CCcaAB;
                                        }
                                    } else {
                                        if (routeId == 383) {
                                            return
                                                0xc7bBa57F8C179EDDBaa62117ddA360e28f3F8252;
                                        } else {
                                            return
                                                0x5e663ED97ea77d393B8858C90d0683bF180E0ffd;
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