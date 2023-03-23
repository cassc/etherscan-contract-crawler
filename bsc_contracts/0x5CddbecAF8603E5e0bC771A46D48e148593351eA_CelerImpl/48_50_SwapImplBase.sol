// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner, OnlySocketDeployer} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Swap Implementation will follow this interface.
 * @author Socket dot tech.
 */
abstract contract SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketDeployFactory;

    /// @notice FunctionSelector used to delegatecall to the performAction function of swap-router-implementation
    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("performAction(address,address,uint256,address,bytes)")
        );

    /// @notice FunctionSelector used to delegatecall to the performActionWithIn function of swap-router-implementation
    bytes4 public immutable SWAP_WITHIN_FUNCTION_SELECTOR =
        bytes4(keccak256("performActionWithIn(address,address,uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketSwapTokens(
        address fromToken,
        address toToken,
        uint256 buyAmount,
        uint256 sellAmount,
        bytes32 routeName,
        address receiver
    );

    /**
     * @notice Construct the base for all SwapImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway, address _socketDeployFactory) {
        socketGateway = _socketGateway;
        socketDeployFactory = _socketDeployFactory;
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
     * @notice function to rescue the ERC20 tokens in the Swap-Implementation contract
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
     * @notice function to rescue the native-balance in the  Swap-Implementation contract
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
     * @notice function to swap tokens on the chain
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param  toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient address of toToken
     * @param data encoded value of properties in the swapData Struct
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    ) external payable virtual returns (uint256);

    /**
     * @notice function to swapWith - swaps tokens on the chain to socketGateway as recipient
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable virtual returns (uint256, address);
}