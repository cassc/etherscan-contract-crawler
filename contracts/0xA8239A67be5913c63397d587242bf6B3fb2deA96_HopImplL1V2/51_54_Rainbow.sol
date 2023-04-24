// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {RAINBOW} from "../../static/RouteIdentifiers.sol";

/**
 * @title Rainbow-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via Rainbow-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of RainbowImplementation
 * @author Socket dot tech.
 */
contract RainbowSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable RainbowIdentifier = RAINBOW;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Rainbow-Router");

    /// @notice address of rainbow-swap-aggregator to swap the tokens on Chain
    address payable public immutable rainbowSwapAggregator;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice rainbow swap aggregator contract is payable to allow ethereum swaps
    /// @dev ensure _rainbowSwapAggregator are set properly for the chainId in which the contract is being deployed
    constructor(
        address _rainbowSwapAggregator,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @notice This method is payable because the caller is doing token transfer and swap operation
     * @param fromToken address of token being Swapped
     * @param toToken address of token that recipient will receive after swap
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient-address
     * @param swapExtraData additional Data to perform Swap via Rainbow-Aggregator
     * @return swapped amount (in toToken Address)
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes calldata swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }
        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapExtraData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapExtraData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            toTokenERC20.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes calldata swapExtraData
    ) external payable override returns (uint256, address) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapExtraData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapExtraData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            socketGateway
        );

        return (returnAmount, toToken);
    }
}