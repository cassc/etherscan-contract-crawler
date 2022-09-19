// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../interfaces/IRangoWormhole.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/Interchain.sol";

/// @title The root contract that handles Rango's interaction with Wormhole and receives message from layerZero
/// @author Marlon
/// @dev This is deployed as a separate contract from RangoV1
contract RangoWormhole is IRangoWormhole, BaseInterchainContract {
    
    /// @notice The address of wormhole contract
    address wormholeRouter;

    /// @notice The initializer of this contract that receives WETH address and initiates the settings
    /// @param _nativeWrappedAddress The address of WETH, WBNB, etc of the current network
    /// @param _wormholeRouter The new address of Wormhole contract
    function initialize(address _nativeWrappedAddress, address _wormholeRouter) public initializer {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.nativeWrappedAddress = _nativeWrappedAddress;

        updateWormholeAddressInternal(_wormholeRouter);

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Emits when the wormhole address is updated
    /// @param _oldRouter The previous router address
    /// @param _newRouter The new router address
    event WormholeAddressUpdated(address _oldRouter, address _newRouter);

    /// @notice A series of events with different status value to help us track the progress of cross-chain swap
    /// @param token The token address in the current network that is being bridged
    /// @param outputAmount The latest observed amount in the path, aka: input amount for source and output amount on dest
    /// @param status The latest status of the overall flow
    /// @param source The source address that initiated the transaction
    /// @param destination The destination address that received the money, ZERO address if not sent to the end-user yet
    event WormholeSwapStatusUpdated(
        address token, 
        uint256 outputAmount, 
        OperationStatus status, 
        address source,
        address destination
    );

    /// @inheritdoc IRangoWormhole
    function wormholeSwap(
        address _fromToken,
        uint _inputAmount,
        WormholeRequest memory _wormholeRequest
    ) external override payable whenNotPaused nonReentrant {
        require(msg.value >= _wormholeRequest._fee, "fee is bigger than the input");

        address router = wormholeRouter;
        require(router != NULL_ADDRESS, "Wormhole router address not set");

        if (_fromToken != NULL_ADDRESS) {
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_fromToken), msg.sender, address(this), _inputAmount);
            approve(_fromToken, router, _inputAmount);
        }
            
        uint value = _fromToken == NULL_ADDRESS ? msg.value : _wormholeRequest._fee;

        if (_wormholeRequest._bridgeType == WormholeBridgeType.TRANSFER_WITH_MESSAGE){
             bytes memory payload = _wormholeRequest._bridgeType == WormholeBridgeType.TRANSFER_WITH_MESSAGE
            ? abi.encode(_wormholeRequest._payload)
            : new bytes(0);

            if (_fromToken == NULL_ADDRESS) {
                IWormholeRouter(router).wrapAndTransferETHWithPayload{value: value}(
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._nonce,
                    payload
                );
            } else {
                IWormholeRouter(router).transferTokensWithPayload{value: value}(
                    _wormholeRequest._fromAddress,
                    _wormholeRequest._finalInput,
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._nonce,
                    payload
                );
            }
        } else {
            if (_fromToken == NULL_ADDRESS) {
                IWormholeRouter(router).wrapAndTransferETH{value: value}(
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._fee,
                    _wormholeRequest._nonce
                );
            } else {
                IWormholeRouter(router).transferTokens{value: value}(
                    _wormholeRequest._fromAddress,
                    _wormholeRequest._finalInput,
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._fee,
                    _wormholeRequest._nonce
                );
            }
        }
        
        emit WormholeSwapStatusUpdated(
            _fromToken,
            _inputAmount,
            OperationStatus.Created,
            _wormholeRequest._payload.originalSender,
            _wormholeRequest._payload.recipient
        );
        
    }

    /// @notice Updates the address of wormhole contract
    /// @param _router The new address of wormhole contract
    function updateWormholeAddress(address _router) public onlyOwner {
        updateWormholeAddressInternal(_router);
    }

    /// @notice The function of this that receives router an address and update router address
    /// @param _router The new address of Wormhole contract
    function updateWormholeAddressInternal(address _router) private {
        address oldAddressRouter = wormholeRouter;
        wormholeRouter = _router;

        emit WormholeAddressUpdated(oldAddressRouter, _router);
    }
}