// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../interfaces/IRango.sol";
import "../../interfaces/IAxelarExecutable.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/IRangoMessageReceiver.sol";
import "../../interfaces/Interchain.sol";
import "../../libraries/LibInterchain.sol";
import "../base/RangoBaseInterchainMiddleware.sol";
import "../../utils/ReentrancyGuard.sol";

/// @title The contract that receives interchain messages
/// @author George
/// @dev This is not a facet, its deployed separately. The refund is handled by whitelisting the payload hash.
contract RangoSatelliteMiddleware is IRango, ReentrancyGuard, IAxelarExecutable, RangoBaseInterchainMiddleware {
    /// Storage ///
    /// @dev keccak256("exchange.rango.facets.satellite")
    bytes32 internal constant SATELLITE_NAMESPACE = hex"e97496d8273588711c444d166dc378e07de45d7ba4c6f83debe0eaef953c5a6f";

    constructor(
        address _owner,
        address _gatewayAddress,
        address _weth
    ) RangoBaseInterchainMiddleware(_owner, address(0), _weth){
        updateSatelliteGatewayInternal(_gatewayAddress);
    }

    struct SatelliteStorage {
        /// @notice The address of satellite contract
        address gatewayAddress;
        // @notice hashes of the transactions that should be refunded
        mapping(bytes32 => bool) refundPayloadHashes;
        // @notice used for refunds where payload cannot be decoded and instead, the receiver address is set manually
        mapping(bytes32 => address) refundPayloadAddresses;
    }

    /// @notice Emitted when the satellite gateway address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGatewayAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emitted when a refund state is updated
    /// @param payloadHash The hash of payload which state is changed
    /// @param enabled The boolean signaling the state. true value means refund is enabled.
    /// @param refundAddress The address that should receive the refund.
    event PayloadHashRefundStateUpdated(bytes32 indexed payloadHash, bool enabled, address refundAddress);
    /// @notice Emitted when a refund has been executed
    /// @param payloadHash The hash of payload which state is changed
    /// @param refundAddress The address that should receive the refund.
    event PayloadHashRefunded(bytes32 indexed payloadHash, address refundAddress);

    /// @notice Updates the address of satellite gateway contract
    /// @param _address The new address of satellite gateway contract
    function updateSatelliteGatewayAddress(address _address) public onlyOwner {
        updateSatelliteGatewayInternal(_address);
    }

    /// @notice Add payload hashes to refund the user.
    /// @param hashes Array of payload hashes to be enabled or disabled for refund
    /// @param booleans Array of booleans corresponding to the hashes. true value means enable refund.
    /// @param addresses addresses that should receive the refund. Can be 0x0000 if the refund should be done based on interchain message
    function updateRefundHashes(
        bytes32[] calldata hashes,
        bool[] calldata booleans,
        address[] calldata addresses
    ) external onlyOwner {
        updateRefundHashesInternal(hashes, booleans, addresses);
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

    /// Satellite Executor:

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external payable nonReentrant {
        SatelliteStorage storage s = getSatelliteStorage();
        bytes32 payloadHash = keccak256(payload);
        if (!IAxelarGateway(s.gatewayAddress).validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
        // todo: implement _execute in future for message passing.
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
        if (!IAxelarGateway(s.gatewayAddress).validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();
        // check if we should refund the user
        if (s.refundPayloadHashes[payloadHash] == true) {
            address refundAddr = s.refundPayloadAddresses[payloadHash];
            if (refundAddr == address(0)) {
                Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
                refundAddr = m.recipient;
            }
            require(refundAddr != address(0), "Cannot refund to burn address");

            address _token = IAxelarGateway(s.gatewayAddress).tokenAddresses(tokenSymbol);
            SafeERC20.safeTransfer(IERC20(_token), refundAddr, amount);
            s.refundPayloadHashes[payloadHash] = false;
            emit PayloadHashRefundStateUpdated(payloadHash, false, refundAddr);
            emit PayloadHashRefunded(payloadHash, refundAddr);
        } else {
            _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        }
    }

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) override internal virtual {
        Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
        SatelliteStorage storage s = getSatelliteStorage();
        address _token = IAxelarGateway(s.gatewayAddress).tokenAddresses(tokenSymbol);
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessageWithTryCatchRefund(_token, amount, m);

        emit SatelliteSwapStatusUpdated(receivedToken, dstAmount, status, m.originalSender, m.recipient);
    }

    function updateSatelliteGatewayInternal(address _address) private {
        SatelliteStorage storage s = getSatelliteStorage();
        address oldAddress = s.gatewayAddress;
        s.gatewayAddress = _address;
        emit SatelliteGatewayAddressUpdated(oldAddress, _address);
    }

    function updateRefundHashesInternal(bytes32[] calldata hashes, bool[] calldata booleans, address[] calldata addresses) private {
        SatelliteStorage storage s = getSatelliteStorage();
        bytes32 hash;
        bool enabled;
        address refundAddr;
        for (uint256 i = 0; i < hashes.length; i++) {
            hash = hashes[i];
            enabled = booleans[i];
            s.refundPayloadHashes[hash] = enabled;
            refundAddr = addresses[i];
            if (refundAddr != address(0))
                s.refundPayloadAddresses[hash] = refundAddr;
            emit PayloadHashRefundStateUpdated(hash, enabled, refundAddr);
        }
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