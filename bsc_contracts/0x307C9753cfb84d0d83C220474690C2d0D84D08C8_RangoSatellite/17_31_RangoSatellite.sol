// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../interfaces/IWETH.sol";
import "../base/BaseProxyContract.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IAxelarExecutable.sol";
import "../../interfaces/IAxelarGasService.sol";
import "../../interfaces/IUniswapV2.sol";
import "../base/BaseInterchainContract.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";


/// @title The root contract that handles Rango's interaction with satellite
/// @author Hellboy
/// @dev This is deployed as a separate contract from RangoV1
contract RangoSatellite is IRangoSatellite, IAxelarExecutable, BaseInterchainContract {
    /// @notice The address of satellite contract
    address gatewayAddress;
    address gasService;

    /// @notice Emits when the satellite gateway address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGatewayAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Emits when the satellite gasService address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGasServiceAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice The constructor of this contract that receives WETH address and initiates the settings
    /// @param _weth The address of WETH, WBNB, etc of the current network
    function initialize(address _weth, address _gatewayAddress, address _gasServiceAddress) public initializer {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.WETH = _weth;

        updateSatelliteGatewayInternal(_gatewayAddress);
        updateSatelliteGasServiceInternal(_gasServiceAddress);

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Updates the address of satellite gateway contract
    /// @param _address The new address of satellite gateway contract
    function updateSatelliteGatewayAddress(address _address) public onlyOwner {
        updateSatelliteGatewayInternal(_address);
    }

    /// @notice Updates the address of satellite gasService contract
    /// @param _address The new address of satellite gasService contract
    function updateSatelliteGasServiceAddress(address _address) public onlyOwner {
        updateSatelliteGasServiceInternal(_address);
    }

    /// @notice Emits when an ERC20 token (non-native) bridge request is sent to satellite bridge
    /// @param _dstChainId The network id of destination chain, ex: 56 for BSC
    /// @param _token The requested token to bridge
    /// @param _receiver The receiver address in the destination chain
    /// @param _amount The requested amount to bridge
    event SatelliteSendTokenCalled(uint256 _dstChainId, address _token, address _receiver, uint256 _amount);
    
    /// @notice A series of events with different status value to help us track the progress of cross-chain swap
    /// @param token The token address in the current network that is being bridged
    /// @param outputAmount The latest observed amount in the path, aka: input amount for source and output amount on dest
    /// @param status The latest status of the overall flow
    /// @param source The source address that initiated the transaction
    /// @param destination The destination address that received the money, ZERO address if not sent to the end-user yet
    event SatelliteSwapStatusUpdated(
        address token, 
        uint256 outputAmount, 
        OperationStatus status, 
        address source,
        address destination
    );

    /// @inheritdoc IRangoSatellite
    function satelliteBridge(
        address _token,
        uint256 _amount,
        SatelliteBridgeRequest memory _request
    ) external payable override whenNotPaused nonReentrant {
        address _receiver = _request.receiver;
        uint _dstChainId = _request.toChainId;

        require(gatewayAddress != ETH, 'Satellite address not set');
        require(block.chainid != _dstChainId, 'Invalid destination Chain! Cannot bridge to the same network.');
        require(_token != ETH, 'Source token address is null! Not supported by axelar!');
        
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_token), msg.sender, address(this), _amount);
        approve(_token, gatewayAddress, _amount);

        if (_request._bridgeType == SatelliteBridgeType.TRANSFER) {
            IAxelarGateway(gatewayAddress).sendToken(_request.toChain, toString(_request.receiver), _request.symbol, _amount);
            emit SatelliteSendTokenCalled(_dstChainId, _token, _receiver, _amount);
        } else {
            require(_request.relayerGas > 0, 'axelar needs native fee for relayer');
            require(msg.value >= _request.relayerGas, 'relayer gas is not provided');

            bytes memory payload = _request._bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE
                ? abi.encode(_request.imMessage)
                : new bytes(0);
    
            emit SatelliteGasServiceAddressUpdated(gasService, gasService);

            IAxelarGasService(gasService).payNativeGasForContractCallWithToken{value: _request.relayerGas}(
                address(this),
                _request.toChain,
                toString(_request.receiver),
                payload,
                _request.symbol,
                _amount,
                address(this) // fixme: set rango fee add
            );
                
            IAxelarGateway(gatewayAddress).callContractWithToken(
                _request.toChain,
                toString(_request.receiver),
                payload,
                _request.symbol,
                _amount
            );
            emit SatelliteSwapStatusUpdated(
                _token,
                _amount,
                OperationStatus.Created,
                _request.imMessage.originalSender,
                _request.imMessage.recipient
            );
        }
    }

    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = '0123456789abcdef';
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = '0';
        byteString[1] = 'x';

        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) override internal virtual {
        Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
        address _token = IAxelarGateway(gatewayAddress).tokenAddresses(tokenSymbol);
        (address receivedToken, uint dstAmount, OperationStatus status) = handleDestinationMessage(_token, amount, m);

        emit SatelliteSwapStatusUpdated(receivedToken, dstAmount, status, m.originalSender, m.recipient);
    }

    function updateSatelliteGatewayInternal(address _address) private {
        address oldAddress = gatewayAddress;
        gatewayAddress = _address;
        IAxelarExecutable.gateway = IAxelarGateway(_address);
        emit SatelliteGatewayAddressUpdated(oldAddress, _address);
    }

    function updateSatelliteGasServiceInternal(address _address) private {
        address oldAddress = gasService;
        gasService = _address;
        emit SatelliteGasServiceAddressUpdated(oldAddress, _address);
    }

}