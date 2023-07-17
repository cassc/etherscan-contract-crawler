// SPDX-License-Identifier: LGPL-3.0-only
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

    function initSatelliteMiddleware(
        address _owner,
        address _gatewayAddress,
        address _weth
    ) external onlyOwner {
        initBaseMiddleware(_owner, address(0), _weth);
        updateSatelliteGatewayInternal(_gatewayAddress);
    }

    struct SatelliteStorage {
        /// @notice The address of satellite contract
        address gatewayAddress;
        // @notice hashes of the transactions that should be refunded
        mapping(bytes32 => bool) refundHashes;
        // @notice for refunds where payload cannot be decoded to get recipient, therefore the receiver address is set manually
        mapping(bytes32 => address) refundHashAddresses;
    }

    /// @notice Emitted when the satellite gateway address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event SatelliteGatewayAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emitted when a refund state is updated
    /// @param refundHash The hash of data for which state is changed
    /// @param enabled The boolean signaling the state. true value means refund is enabled.
    /// @param refundAddress The address that should receive the refund.
    event RefundHashStateUpdated(bytes32 indexed refundHash, bool enabled, address refundAddress);
    /// @notice Emitted when a refund has been executed
    /// @param refundHash The hash of data for which state is changed
    /// @param refundAddress The address that should receive the refund.
    event PayloadHashRefunded(bytes32 indexed refundHash, address refundAddress);

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
        bytes32 refundHash = encodeDataToBytes32(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount);
        if (s.refundHashes[refundHash] == true) {
            address refundAddr = s.refundHashAddresses[refundHash];
            address requestId = LibSwapper.ETH;
            address originalSender = LibSwapper.ETH;
            uint16 dAppTag;
            if (refundAddr == address(0)) {
                Interchain.RangoInterChainMessage memory m = abi.decode((payload), (Interchain.RangoInterChainMessage));
                refundAddr = m.recipient;
                requestId = m.requestId;
                originalSender = m.originalSender;
                dAppTag = m.dAppTag;
            }
            require(refundAddr != address(0), "Cannot refund to burn address");

            address _token = IAxelarGateway(s.gatewayAddress).tokenAddresses(tokenSymbol);
            SafeERC20.safeTransfer(IERC20(_token), refundAddr, amount);
            s.refundHashes[refundHash] = false;
            s.refundHashAddresses[refundHash] = address(0);
            emit RefundHashStateUpdated(refundHash, false, refundAddr);
            emit PayloadHashRefunded(refundHash, refundAddr);
            emit RangoBridgeCompleted(
                requestId,
                _token,
                originalSender,
                refundAddr,
                amount,
                CrossChainOperationStatus.RefundInDestination,
                dAppTag
            );
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
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(_token, amount, m);

        emit RangoBridgeCompleted(
            m.requestId,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    /// @notice just a helper function to create the hash of data for refunds
    function encodeDataToBytes32(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata tokenSymbol,
        uint256 amount
    ) public pure returns (bytes32){
        return keccak256(abi.encode(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount));
    }

    function updateSatelliteGatewayInternal(address _address) private {
        require(_address != address(0), "Invalid Gateway Address");
        SatelliteStorage storage s = getSatelliteStorage();
        address oldAddress = s.gatewayAddress;
        s.gatewayAddress = _address;
        emit SatelliteGatewayAddressUpdated(oldAddress, _address);
    }

    function updateRefundHashesInternal(bytes32[] calldata hashes, bool[] calldata booleans, address[] calldata addresses) private {
        require(hashes.length == booleans.length && booleans.length == addresses.length);
        SatelliteStorage storage s = getSatelliteStorage();
        bytes32 hash;
        bool enabled;
        address refundAddr;
        for (uint256 i = 0; i < hashes.length; i++) {
            hash = hashes[i];
            enabled = booleans[i];
            s.refundHashes[hash] = enabled;
            refundAddr = addresses[i];
            if (refundAddr != address(0))
                s.refundHashAddresses[hash] = refundAddr;
            emit RefundHashStateUpdated(hash, enabled, refundAddr);
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