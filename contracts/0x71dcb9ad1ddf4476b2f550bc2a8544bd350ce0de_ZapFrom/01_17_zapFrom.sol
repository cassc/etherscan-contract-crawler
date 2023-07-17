// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {WETH} from "lib/solmate/src/tokens/WETH.sol";
import {SwapController} from "./controllers/swapController.sol";
import {IErrors} from "../interfaces/IErrors.sol";
import {IStargateRouter} from "../interfaces/bridges/IStargateRouter.sol";
import {ILayerZeroRouter} from "../interfaces/bridges/ILayerZeroRouter.sol";

contract ZapFrom is IErrors, SwapController {
    using SafeTransferLib for ERC20;
    uint16 public constant ARBITRUM_CHAIN_ID = 110; // NOTE: Id used by Stargate for Arbitrum
    // NOTE: This is the abi.encodePacked destAddress
    bytes public constant ARB_RECEIVER =
        "0x9c668a934611706f84f5b22705ecdf94c3349c5d";
    address public immutable stargateRouter;
    address public immutable stargateRouterEth;
    address public immutable layerZeroRouter;
    address public immutable y2kArbRouter;
    // TODO: Make this constant with pre-computed address and additional var
    // NOTE: abi.encodePacked(remoteAddress, localAddress)
    bytes public layerZeroRemoteAndLocal;

    struct Config {
        address _stargateRouter;
        address _stargateRouterEth;
        address _layerZeroRouterLocal;
        address _y2kArbRouter;
        address _uniswapV2Factory;
        address _sushiSwapFactory;
        address _uniswapV3Factory;
        address _balancerVault;
        address _wethAddress;
        bytes _primaryInitHash;
        bytes _secondaryInitHash;
    }

    constructor(
        Config memory _config
    )
        SwapController(
            _config._uniswapV2Factory,
            _config._sushiSwapFactory,
            _config._uniswapV3Factory,
            _config._balancerVault,
            _config._wethAddress,
            _config._primaryInitHash,
            _config._secondaryInitHash
        )
    {
        if (_config._stargateRouter == address(0)) revert InvalidInput();
        if (_config._stargateRouterEth == address(0)) revert InvalidInput();
        if (_config._layerZeroRouterLocal == address(0)) revert InvalidInput();
        if (_config._y2kArbRouter == address(0)) revert InvalidInput();
        stargateRouter = _config._stargateRouter;
        stargateRouterEth = _config._stargateRouterEth;
        layerZeroRouter = _config._layerZeroRouterLocal;
        // TODO: Remove this for a constant
        layerZeroRemoteAndLocal = abi.encodePacked(
            _config._y2kArbRouter,
            address(this)
        );
        y2kArbRouter = _config._y2kArbRouter;
    }

    //////////////////////////////////////////////
    //                 PUBLIC                   //
    //////////////////////////////////////////////
    /// @param amountIn The qty of local _token contract tokens
    /// @param fromToken The fromChain token address
    /// @param srcPoolId The poolId for the fromChain
    /// @param dstPoolId The poolId for the toChain
    /// @param payload The encoded payload to deposit into vault abi.encode(receiver, vaultId)
    function bridge(
        uint amountIn,
        address fromToken,
        uint16 srcPoolId,
        uint16 dstPoolId,
        bytes calldata payload
    ) external payable {
        if (msg.value == 0) revert InvalidInput();
        if (amountIn == 0) revert InvalidInput();

        if (fromToken != address(0)) {
            ERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
        }
        _bridge(amountIn, fromToken, srcPoolId, dstPoolId, payload);
    }

    // TODO: Need to implement this
    function permitSwapAndBridge(
        uint amountIn,
        address fromToken,
        address receivedToken,
        uint16 srcPoolId,
        uint16 dstPoolId,
        bytes calldata swapPayload,
        bytes calldata bridgePayload
    ) public payable {
        if (msg.value == 0) revert InvalidInput();
        if (amountIn == 0) revert InvalidInput();

        // TODO: implement permit2 for the fromToken transfer
        ERC20(fromToken).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 receivedAmount = _swap(
            swapPayload[0],
            amountIn,
            swapPayload[32:]
        );
        _bridge(
            receivedAmount,
            receivedToken,
            srcPoolId,
            dstPoolId,
            bridgePayload
        );
    }

    function swapAndBridge(
        uint amountIn,
        address fromToken,
        address receivedToken,
        uint16 srcPoolId,
        uint16 dstPoolId,
        bytes1 dexId,
        bytes calldata swapPayload,
        bytes calldata bridgePayload
    ) external payable {
        if (msg.value == 0) revert InvalidInput();
        if (amountIn == 0) revert InvalidInput();

        ERC20(fromToken).safeTransferFrom(msg.sender, address(this), amountIn);

        // NOTE: Check if not Balancer as fromToken location is dynamic
        uint256 receivedAmount;
        if (dexId != 0x05) {
            receivedAmount = _swap(dexId, amountIn, swapPayload);
        } else {
            ERC20(fromToken).safeApprove(balancerVault, amountIn);
            receivedAmount = _swapBalancer(swapPayload);
        }

        if (receivedToken == wethAddress) {
            WETH(wethAddress).withdraw(receivedAmount);
            receivedToken = address(0);
        }

        _bridge(
            receivedAmount,
            receivedToken,
            srcPoolId,
            dstPoolId,
            bridgePayload
        );
    }

    // TODO: Check the construction of the remote and local variables
    function withdraw(bytes memory payload) external payable {
        if (msg.value == 0) revert InvalidInput();
        ILayerZeroRouter(layerZeroRouter).send{value: msg.value}(
            uint16(ARBITRUM_CHAIN_ID), // destination LayerZero chainId
            layerZeroRemoteAndLocal, // send to this address on the destination
            payload, // bytes payload
            payable(msg.sender), // refund address
            address(0x0), // future parameter
            bytes("") // adapterParams (see "Advanced Features")
        );
    }

    //////////////////////////////////////////////
    //                 INTERNAL                 //
    //////////////////////////////////////////////

    function _bridge(
        uint amountIn,
        address fromToken,
        uint16 srcPoolId,
        uint16 dstPoolId,
        bytes calldata payload
    ) private {
        if (fromToken == address(0)) {
            // NOTE: When sending after a swap msg.value will be < amountIn as only contains the fee
            // When sending without swap msg.value will be > amountIn as contains fee + amountIn
            uint256 msgValue = msg.value > amountIn
                ? msg.value
                : amountIn + msg.value;
            IStargateRouter(stargateRouterEth).swapETHAndCall{value: msgValue}(
                uint16(ARBITRUM_CHAIN_ID), // destination Stargate chainId
                payable(msg.sender), // refund additional messageFee to this address
                ARB_RECEIVER, // the receiver of the destination ETH
                IStargateRouter.SwapAmount(amountIn, (amountIn * 950) / 1000),
                IStargateRouter.lzTxObj(200000, 0, "0x"), // default lzTxObj
                payload // the payload to send to the destination
            );
        } else {
            ERC20(fromToken).safeApprove(stargateRouter, amountIn);
            // Sends tokens to the destChain
            IStargateRouter(stargateRouter).swap{value: msg.value}(
                uint16(ARBITRUM_CHAIN_ID), // the destination chain id
                srcPoolId, // the source Stargate poolId
                dstPoolId, // the destination Stargate poolId
                payable(msg.sender), // refund adddress. if msg.sender pays too much gas, return extra eth
                amountIn, // total tokens to send to destination chain
                (amountIn * 950) / 1000, // min amount allowed out
                IStargateRouter.lzTxObj(200000, 0, "0x"), // default lzTxObj
                ARB_RECEIVER, // destination address, the sgReceive() implementer
                payload
            );
        }
    }

    receive() external payable {}
}