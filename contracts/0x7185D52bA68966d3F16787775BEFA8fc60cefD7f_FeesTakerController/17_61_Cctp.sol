// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/cctp.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {CCTP} from "../../static/RouteIdentifiers.sol";

/**
 * @title CCTP-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hyphen-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of HyphenImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract CctpImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable cctpIndentifier = CCTP;

    /// @notice Function-selector for ERC20-token bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens

    bytes4 public immutable CCTP_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,bytes32,address,address,uint256,uint32,uint256)"
            )
        );

    bytes4 public immutable CCTP_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,uint32,uint256,uint256,bytes32))"
            )
        );

    TokenMessenger public immutable tokenMessenger;
    address public immutable feeCollector;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure liquidityPoolManager-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _tokenMessenger,
        address _feeCollector,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        tokenMessenger = TokenMessenger(_tokenMessenger);
        feeCollector = _feeCollector;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct CctpData {
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver
        address receiverAddress;
        uint32 destinationDomain;
        /// @notice chainId of destination

        uint256 toChainId;
        /// @notice destinationDomain
        uint256 feeAmount;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    struct CctoDataNoToken {
        address receiverAddress;
        uint32 destinationDomain;
        uint256 toChainId;
        uint256 feeAmount;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for HyphenBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        CctpData memory cctpData = abi.decode(bridgeData, (CctpData));

        if (cctpData.token == NATIVE_TOKEN_ADDRESS) {
            revert("Native token not supported");
        } else {
            ERC20(cctpData.token).transfer(feeCollector, cctpData.feeAmount);
            tokenMessenger.depositForBurn(
                amount - cctpData.feeAmount,
                cctpData.destinationDomain,
                bytes32(uint256(uint160(cctpData.receiverAddress))),
                cctpData.token
            );
        }

        emit SocketBridge(
            amount,
            cctpData.token,
            cctpData.toChainId,
            cctpIndentifier,
            msg.sender,
            cctpData.receiverAddress,
            cctpData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param cctpData encoded data for cctpData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        CctoDataNoToken calldata cctpData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );
        if (token == NATIVE_TOKEN_ADDRESS) {
            revert("Native token not supported");
        } else {
            ERC20(token).transfer(feeCollector, cctpData.feeAmount);
            tokenMessenger.depositForBurn(
                bridgeAmount - cctpData.feeAmount,
                cctpData.destinationDomain,
                bytes32(uint256(uint160(cctpData.receiverAddress))),
                token
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            cctpData.toChainId,
            cctpIndentifier,
            msg.sender,
            cctpData.receiverAddress,
            cctpData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param token address of token being bridged
     * @param toChainId chainId of destination
     */
    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        uint32 destinationDomain,
        uint256 feeAmount
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.transfer(feeCollector, feeAmount);
        tokenMessenger.depositForBurn(
            amount - feeAmount,
            destinationDomain,
            bytes32(uint256(uint160(receiverAddress))),
            token
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            cctpIndentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}