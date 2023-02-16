// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../interfaces/IWETH.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IRango.sol";
import "../../interfaces/IAxelarGateway.sol";
import "../../interfaces/IAxelarGasService.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";
import "../../libraries/LibInterchain.sol";
import "../../utils/LibTransform.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../libraries/LibDiamond.sol";

/// @title The root contract that handles Rango's interaction with satellite
/// @author 0xiden
/// @dev This facet should be added to diamond. This facet doesn't and shouldn't receive messages. Handling messages is done through middleware.
contract RangoSatelliteFacet is IRango, ReentrancyGuard, IRangoSatellite {
    /// Storage ///
    /// @dev keccak256("exchange.rango.facets.satellite")
    bytes32 internal constant SATELLITE_NAMESPACE = hex"e97496d8273588711c444d166dc378e07de45d7ba4c6f83debe0eaef953c5a6f";

    struct SatelliteStorage {
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
    function initSatellite(SatelliteStorage calldata addresses) external {
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
        IRango.CrossChainOperationStatus status,
        address source,
        address destination
    );

    /// @notice Executes a DEX (arbitrary) call + a Satellite bridge call
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function satelliteSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable nonReentrant {
        uint out;
        uint bridgeAmount;
        // if toToken is native coin and the user has not paid fee in msg.value,
        // then the user can pay bridge fee using output of swap.
        if (request.toToken == LibSwapper.ETH && msg.value == 0) {
            (out,) = LibSwapper.onChainSwapsPreBridge(request, calls, 0);
            bridgeAmount = out - bridgeRequest.relayerGas;
        }
        else {
            (out,) = LibSwapper.onChainSwapsPreBridge(request, calls, bridgeRequest.relayerGas);
            bridgeAmount = out;
        }

        doSatelliteBridge(bridgeRequest, request.toToken, bridgeAmount);
        // event emission
        emit RangoBridgeInitiated(
            request.requestId,
            request.toToken,
            bridgeAmount,
            LibTransform.stringToAddress(bridgeRequest.receiver),
            "",
            bridgeRequest.toChainId,
            bridgeRequest.bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE,
            bridgeRequest.imMessage.actionType != Interchain.ActionType.NO_ACTION,
            uint8(BridgeType.Axelar),
            request.dAppTag
        );
    }

    /// @notice Executes a bridging via satellite
    /// @param request The extra fields required by the satellite bridge
    function satelliteBridge(
        SatelliteBridgeRequest memory request,
        RangoBridgeRequest memory bridgeRequest
    ) external payable nonReentrant {
        uint amount = bridgeRequest.amount;
        address token = bridgeRequest.token;
        uint amountWithFee = amount + LibSwapper.sumFees(bridgeRequest);
        // transfer tokens if necessary
        if (token != LibSwapper.ETH) {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amountWithFee);
            require(msg.value >= request.relayerGas);
        } else {
            require(msg.value >= amountWithFee + request.relayerGas);
        }
        LibSwapper.collectFees(bridgeRequest);
        doSatelliteBridge(request, token, amount);
        // event emission
        emit RangoBridgeInitiated(
            bridgeRequest.requestId,
            token,
            amount,
            LibTransform.stringToAddress(request.receiver),
            "",
            request.toChainId,
            request.bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE,
            request.imMessage.actionType != Interchain.ActionType.NO_ACTION,
            uint8(BridgeType.Axelar),
            bridgeRequest.dAppTag
        );
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

        LibSwapper.BaseSwapperStorage storage baseStorage = LibSwapper.getBaseSwapperStorage();
        address bridgeToken = token;
        address refAddress = baseStorage.feeContractAddress;
        if (token == LibSwapper.ETH) {
            bridgeToken = baseStorage.WETH;
            IWETH(bridgeToken).deposit{value : amount}();
        }
        if (refAddress == LibSwapper.ETH) {
            refAddress = msg.sender;
        }
        require(bridgeToken != LibSwapper.ETH, 'Source token address is null! Not supported by axelar!');
        LibSwapper.approve(bridgeToken, s.gatewayAddress, amount);

        if (request.bridgeType == SatelliteBridgeType.TRANSFER) {
            IAxelarGateway(s.gatewayAddress).sendToken(request.toChain, request.receiver, request.symbol, amount);
            emit SatelliteSendTokenCalled(dstChainId, bridgeToken, request.receiver, amount);
        } else {
            require(s.gasService != LibSwapper.ETH, 'Satellite gasService address not set');
            require(request.relayerGas > 0, 'axelar needs native fee for relayer');

            bytes memory payload = request.bridgeType == SatelliteBridgeType.TRANSFER_WITH_MESSAGE
            ? abi.encode(request.imMessage)
            : new bytes(0);
            IAxelarGasService(s.gasService).payNativeGasForContractCallWithToken{value : request.relayerGas}(
                address(this),
                request.toChain,
                request.receiver,
                payload,
                request.symbol,
                amount,
                refAddress
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
                IRango.CrossChainOperationStatus.Created,
                request.imMessage.originalSender,
                request.imMessage.recipient
            );
        }
    }

    function updateSatelliteGatewayInternal(address _address) private {
        SatelliteStorage storage s = getSatelliteStorage();
        address oldAddress = s.gatewayAddress;
        s.gatewayAddress = _address;
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