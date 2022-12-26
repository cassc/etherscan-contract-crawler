// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../interfaces/IWETH.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IRango.sol";
import "../../interfaces/IAxelarExecutable.sol";
import "../../interfaces/IAxelarGasService.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";
import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../libraries/LibDiamond.sol";


/// @title The root contract that handles Rango's interaction with satellite
/// @author 0xiden
/// @dev This is deployed as a separate contract from RangoV1
contract RangoSatelliteFacet is IRango, ReentrancyGuard, IRangoSatellite, IAxelarExecutable {
    /// Storage ///
    /// @dev keccak256("exchange.rango.facets.satellite")
    bytes32 internal constant SATELLITE_NAMESPACE = hex"e97496d8273588711c444d166dc378e07de45d7ba4c6f83debe0eaef953c5a6f";

    struct SatelliteStorage {
        /// @notice The address of satellite contract
        address gatewayAddress;
        /// @notice The address of satellite gas service contract
        address gasService;
        IAxelarGateway gateway;
    }

    struct SatelliteConfig {
        /// @notice The address of satellite contract
        address gatewayAddress;
        /// @notice The address of satellite gas service contract
        address gasService;
    }

    /// @notice Emitted when the satellite gateway address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGatewayAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Emitted when the satellite gasService address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGasServiceAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Initialize the contract.
    /// @param addresses The addresses of whitelist contracts for bridge
    function initSatellite(SatelliteConfig calldata addresses) external {
        LibDiamond.enforceIsContractOwner();
        updateSatelliteGatewayInternal(addresses.gatewayAddress);
        updateSatelliteGasServiceInternal(addresses.gasService);
    }

    /// @notice Updates the address of satellite gateway contract
    /// @param _address The new address of satellite gateway contract
    function updateSatelliteGatewayAddress(address _address) public {
        LibDiamond.enforceIsContractOwner();
        updateSatelliteGatewayInternal(_address);
    }

    /// @notice Updates the address of satellite gasService contract
    /// @param _address The new address of satellite gasService contract
    function updateSatelliteGasServiceAddress(address _address) public {
        LibDiamond.enforceIsContractOwner();
        updateSatelliteGasServiceInternal(_address);
    }

    /// @notice Emitted when an ERC20 token (non-native) bridge request is sent to satellite bridge
    /// @param _dstChainId The network id of destination chain, ex: 56 for BSC
    /// @param _token The requested token to bridge
    /// @param _receiver The receiver address in the destination chain
    /// @param _amount The requested amount to bridge
    event SatelliteSendTokenCalled(uint256 _dstChainId, address _token, string _receiver, uint256 _amount);

    /// @notice A series of events with different status value to help us track the progress of cross-chain swap
    /// @param token The token address in the current network that is being bridged
    /// @param outputAmount The latest observed amount in the path, aka: input amount for source and output amount on dest
    /// @param status The latest status of the overall flow
    /// @param source The source address that initiated the transaction
    /// @param destination The destination address that received the money, ZERO address if not sent to the end-user yet
    event SatelliteSwapStatusUpdated(
        address token,
        uint256 outputAmount,
        LibInterchain.OperationStatus status,
        address source,
        address destination
    );

    /// Satellite Executor:

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external payable nonReentrant {
        SatelliteStorage storage s = getSatelliteStorage();
        bytes32 payloadHash = keccak256(payload);
        if (!s.gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
        // todo: _execute is not implemented.
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external payable nonReentrant {
        SatelliteStorage storage s = getSatelliteStorage();
        bytes32 payloadHash = keccak256(payload);
        if (!s.gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    /// @notice Executes a DEX (arbitrary) call + a Satellite bridge call
    /// @dev The Satellite part is handled in the RangoSatellite.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function satelliteBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable nonReentrant {
        (uint out, uint value) = LibSwapper.onChainSwapsPreBridge(request, calls, 0);
        if (request.toToken != LibSwapper.ETH)
            doSatelliteBridge(bridgeRequest, request.toToken, out);
    }

    /// @notice Executes a bridging via satellite
    /// @param request The extra fields required by the satellite bridge
    /// @param token The requested token to bridge
    /// @param amount The requested amount to bridge
    function satelliteBridge(
        SatelliteBridgeRequest memory request,
        address token,
        uint256 amount
    ) external payable nonReentrant {
        // transfer tokens if necessary
        if (token == LibSwapper.ETH) {
            require(msg.value >= amount, "Insufficient ETH sent for bridging");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        }
        doSatelliteBridge(request, token, amount);
    }

    /// @notice Executes a bridging via satellite
    /// @param request The extra fields required by the satellite bridge
    /// @param token The requested token to bridge
    /// @param amount The requested amount to bridge
    function doSatelliteBridge(
        SatelliteBridgeRequest memory request,
        address token,
        uint256 amount
    ) internal {
        SatelliteStorage storage s = getSatelliteStorage();
        uint dstChainId = request.toChainId;

        require(s.gatewayAddress != LibSwapper.ETH, 'Satellite gateway address not set');
        require(block.chainid != dstChainId, 'Invalid destination Chain! Cannot bridge to the same network.');
        require(token != LibSwapper.ETH, 'Source token address is null! Not supported by axelar!');

        LibSwapper.approve(token, s.gatewayAddress, amount);

        if (request.bridgeType == SatelliteBridgeType.TRANSFER) {
            IAxelarGateway(s.gatewayAddress).sendToken(request.toChain, request.receiver, request.symbol, amount);
            emit SatelliteSendTokenCalled(dstChainId, token, request.receiver, amount);
        } else {
            require(s.gasService != LibSwapper.ETH, 'Satellite gasService address not set');
            require(request.relayerGas > 0, 'axelar needs native fee for relayer');
            require(msg.value >= request.relayerGas, 'relayer gas is not provided');

            bytes memory payload = request.bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE
            ? abi.encode(request.imMessage)
            : new bytes(0);
            // todo: what about the excess fees? send back to user?
            IAxelarGasService(s.gasService).payNativeGasForContractCallWithToken{value : request.relayerGas}(
                address(this),
                request.toChain,
                request.receiver,
                payload,
                request.symbol,
                amount,
                msg.sender // fixme: set rango fee add
            );

            IAxelarGateway(s.gatewayAddress).callContractWithToken(
                request.toChain,
                request.receiver,
                payload,
                request.symbol,
                amount
            );
            emit SatelliteSwapStatusUpdated(
                token,
                amount,
                LibInterchain.OperationStatus.Created,
                request.imMessage.originalSender,
                request.imMessage.recipient
            );
        }
    }

    function toString(address a) internal pure returns (string memory) { // TODO: remove this? not used anymore?
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
        string memory sourceChain, // TODO: why ignore this?
        string memory sourceAddress, // TODO: why ignore this?
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) override internal virtual {
        Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
        SatelliteStorage storage s = getSatelliteStorage();
        address _token = IAxelarGateway(s.gatewayAddress).tokenAddresses(tokenSymbol);
        (address receivedToken, uint dstAmount, LibInterchain.OperationStatus status) = LibInterchain.handleDestinationMessage(_token, amount, m);

        emit SatelliteSwapStatusUpdated(receivedToken, dstAmount, status, m.originalSender, m.recipient);
    }

    function updateSatelliteGatewayInternal(address _address) private {
        SatelliteStorage storage s = getSatelliteStorage();
        address oldAddress = s.gatewayAddress;
        s.gatewayAddress = _address;
        s.gateway = IAxelarGateway(_address);
        emit SatelliteGatewayAddressUpdated(oldAddress, _address);
    }

    function updateSatelliteGasServiceInternal(address _address) private {
        SatelliteStorage storage s = getSatelliteStorage();
        address oldAddress = s.gasService;
        s.gasService = _address;
        emit SatelliteGasServiceAddressUpdated(oldAddress, _address);
    }

    /// @dev fetch local storage
    function getSatelliteStorage() private pure returns (SatelliteStorage storage s) {
        bytes32 namespace = SATELLITE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}