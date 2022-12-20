// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../interfaces/IRangoWormhole.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/Interchain.sol";
import "../../interfaces/IWormholeTokenBridge.sol";
import "../../interfaces/WormholeBridgeStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title The root contract that handles Rango's interaction with Wormhole and receives message from layerZero
/// @author Marlon
/// @dev This is deployed as a separate contract from RangoV1
contract RangoWormhole is IRangoWormhole, BaseInterchainContract {
    
    /// @notice The address of wormhole contract
    address wormholeRouter;

    /// @notice The initializer of this contract that receives WETH address and initiates the settings
    /// @param _WETH The address of WETH, WBNB, etc of the current network
    /// @param _wormholeRouter The new address of Wormhole contract
    function initialize(address _WETH, address _wormholeRouter) public initializer {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.WETH = _WETH;

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

        require(wormholeRouter != ETH, "Wormhole router address not set");

        if (_fromToken != ETH) {
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_fromToken), msg.sender, address(this), _inputAmount);
            approve(_fromToken, wormholeRouter, _inputAmount);
        }
            
        if (_wormholeRequest._bridgeType == WormholeBridgeType.TRANSFER_WITH_MESSAGE) {
             bytes memory payload = abi.encode(_wormholeRequest._payload);

            if (_fromToken == ETH) {
                IWormholeRouter(wormholeRouter).wrapAndTransferETHWithPayload{value: msg.value}(
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._nonce,
                    payload
                );
            } else {
                IWormholeRouter(wormholeRouter).transferTokensWithPayload(
                    _wormholeRequest._fromAddress,
                    _inputAmount,
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._nonce,
                    payload
                );
            }
        } else {
            if (_fromToken == ETH) {
                IWormholeRouter(wormholeRouter).wrapAndTransferETH{value: msg.value}(
                    _wormholeRequest._recipientChain,
                    _wormholeRequest._targetAddress,
                    _wormholeRequest._fee,
                    _wormholeRequest._nonce
                );
            } else {
                IWormholeRouter(wormholeRouter).transferTokens(
                    _wormholeRequest._fromAddress,
                    _inputAmount,
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
    
    function completeTransferWithPayload(
        bytes memory vaas
    ) external whenNotPaused nonReentrant
    {
        address wormholeTokenBridgeAddress = address(wormholeRouter);
        IWormholeTokenBridge coreBridge = IWormholeTokenBridge(wormholeTokenBridgeAddress);
        bytes memory payload = coreBridge.completeTransferWithPayload(vaas);
        
        WormholeBridgeStructs.TransferWithPayload memory transfer = coreBridge.parseTransferWithPayload(payload);
        Interchain.RangoInterChainMessage memory m = abi.decode((transfer.payload), (Interchain.RangoInterChainMessage));
        (,bytes memory queriedDecimals) = (address(uint160(uint256(transfer.tokenAddress)))).staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        // adjust decimals
        uint256 exactAmount = deNormalizeAmount(transfer.amount, decimals);
        (address receivedToken, uint dstAmount, OperationStatus status) = handleDestinationMessage(
                address(uint160(uint256(transfer.tokenAddress))),
                exactAmount,
                m
        );

        emit WormholeSwapStatusUpdated(
            receivedToken,
            dstAmount,
            status,
            m.originalSender,
            m.recipient
        );
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
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