// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {OnlySocketGatewayOwner, OnlySocketDeployer} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Bridge Implementation will follow this interface.
 */
abstract contract BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketDeployFactory;

    /// @notice immutable variable with instance of SocketRoute to access route functions
    ISocketRoute public immutable socketRoute;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketBridge(
        uint256 amount,
        address token,
        uint256 toChainId,
        bytes32 bridgeName,
        address sender,
        address receiver,
        bytes32 metadata
    );

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     * @param _socketDeployFactory Socket Deploy Factory address, an immutable variable to set.
     */
    constructor(address _socketGateway, address _socketDeployFactory) {
        socketGateway = _socketGateway;
        socketDeployFactory = _socketDeployFactory;
        socketRoute = ISocketRoute(_socketGateway);
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketDeployFactory() {
        if (msg.sender != socketDeployFactory) {
            revert OnlySocketDeployer();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    function killme() external isSocketDeployFactory {
        selfdestruct(payable(msg.sender));
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to bridge which is succeeding the swap function
     * @notice this function is to be used only when bridging as a succeeding step
     * @notice All bridge implementation contracts must implement this function
     * @notice bridge-implementations will have a bridge specific struct with properties used in bridging
     * @param bridgeData encoded value of properties in the bridgeData Struct
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable virtual;
}