// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {ZEROX} from "../../static/RouteIdentifiers.sol";

/**
 * @title ZeroX-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via ZeroX-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of ZeroX-Swap-Implementation
 * @author Socket dot tech.
 */
contract ZeroXSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable ZeroXIdentifier = ZEROX;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Zerox-Router");

    /// @notice address of ZeroX-Exchange-Proxy to swap the tokens on Chain
    address payable public immutable zeroXExchangeProxy;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice ZeroXExchangeProxy contract is payable to allow ethereum swaps
    /// @dev ensure _zeroXExchangeProxy are set properly for the chainId in which the contract is being deployed
    constructor(
        address _zeroXExchangeProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @dev This is called only when there is a request for a swap.
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken is to be swapped
     * @param amount amount to be swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData data required for zeroX Exchange to get the swap done
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

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            erc20ToToken.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
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

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            socketGateway
        );

        return (returnAmount, toToken);
    }
}