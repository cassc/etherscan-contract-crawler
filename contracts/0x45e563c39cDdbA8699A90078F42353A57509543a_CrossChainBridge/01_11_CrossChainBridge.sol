// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ILayerZeroUserApplicationConfig} from "layer-zero/interfaces/ILayerZeroUserApplicationConfig.sol";
import {ILayerZeroEndpoint} from "layer-zero/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "layer-zero/interfaces/ILayerZeroReceiver.sol";
import {BytesLib} from "layer-zero/util/BytesLib.sol";

import {RolesConsumer} from "modules/ROLES/OlympusRoles.sol";
import {ROLESv1} from "modules/ROLES/ROLES.v1.sol";
import {MINTRv1} from "modules/MINTR/MINTR.v1.sol";

import "src/Kernel.sol";

/// @notice Message bridge for cross-chain OHM transfers.
/// @dev Uses LayerZero as communication protocol.
/// @dev Each chain needs to `setTrustedRemoteAddress` for each remote address
///      it intends to receive from.
contract CrossChainBridge is
    Policy,
    RolesConsumer,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using BytesLib for bytes;

    // Bridge errors
    error Bridge_InsufficientAmount();
    error Bridge_InvalidCaller();
    error Bridge_InvalidMessageSource();
    error Bridge_NoStoredMessage();
    error Bridge_InvalidPayload();
    error Bridge_DestinationNotTrusted();
    error Bridge_NoTrustedPath();
    error Bridge_Deactivated();
    error Bridge_TrustedRemoteUninitialized();

    // Bridge-specific events
    event BridgeTransferred(address indexed sender_, uint256 amount_, uint16 indexed dstChain_);
    event BridgeReceived(address indexed receiver_, uint256 amount_, uint16 indexed srcChain_);

    // LZ app events
    event MessageFailed(
        uint16 srcChainId_,
        bytes srcAddress_,
        uint64 nonce_,
        bytes payload_,
        bytes reason_
    );
    event RetryMessageSuccess(
        uint16 srcChainId_,
        bytes srcAddress_,
        uint64 nonce_,
        bytes32 payloadHash_
    );
    event SetPrecrime(address precrime_);
    event SetTrustedRemote(uint16 remoteChainId_, bytes path_);
    event SetTrustedRemoteAddress(uint16 remoteChainId_, bytes remoteAddress_);
    event SetMinDstGas(uint16 dstChainId_, uint16 type_, uint256 _minDstGas);
    event BridgeStatusSet(bool isActive_);

    // Modules
    MINTRv1 public MINTR;

    ILayerZeroEndpoint public immutable lzEndpoint;
    ERC20 public ohm;

    /// @notice Flag to determine if bridge is allowed to send messages or not
    bool public bridgeActive;

    // LZ app state

    /// @notice Storage for failed messages on receive.
    /// @notice chainID => source address => endpoint nonce
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    /// @notice Trusted remote paths. Must be set by admin.
    mapping(uint16 => bytes) public trustedRemoteLookup;

    /// @notice LZ precrime address. Currently unused.
    address public precrime;

    //============================================================================================//
    //                                        POLICY SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_, address endpoint_) Policy(kernel_) {
        lzEndpoint = ILayerZeroEndpoint(endpoint_);
        bridgeActive = true;
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        ROLES = ROLESv1(getModuleAddress(dependencies[1]));

        ohm = ERC20(address(MINTR.ohm()));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        Keycode MINTR_KEYCODE = MINTR.KEYCODE();

        permissions = new Permissions[](3);
        permissions[0] = Permissions(MINTR_KEYCODE, MINTR.mintOhm.selector);
        permissions[1] = Permissions(MINTR_KEYCODE, MINTR.burnOhm.selector);
        permissions[2] = Permissions(MINTR_KEYCODE, MINTR.increaseMintApproval.selector);
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @notice Send OHM to an eligible chain
    function sendOhm(uint16 dstChainId_, address to_, uint256 amount_) external payable {
        if (!bridgeActive) revert Bridge_Deactivated();
        if (ohm.balanceOf(msg.sender) < amount_) revert Bridge_InsufficientAmount();

        bytes memory payload = abi.encode(to_, amount_);

        MINTR.burnOhm(msg.sender, amount_);
        _sendMessage(dstChainId_, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);

        emit BridgeTransferred(msg.sender, amount_, dstChainId_);
    }

    /// @notice Implementation of receiving an LZ message
    /// @dev    Function must be public to be called by low-level call in lzReceive
    function _receiveMessage(
        uint16 srcChainId_,
        bytes memory,
        uint64,
        bytes memory payload_
    ) internal {
        (address to, uint256 amount) = abi.decode(payload_, (address, uint256));

        MINTR.increaseMintApproval(address(this), amount);
        MINTR.mintOhm(to, amount);

        emit BridgeReceived(to, amount, srcChainId_);
    }

    // ========= LZ Receive Functions ========= //

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        bytes calldata payload_
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint)) revert Bridge_InvalidCaller();

        // Will still block the message pathway from (srcChainId, srcAddress).
        // Should not receive messages from untrusted remote.
        bytes memory trustedRemote = trustedRemoteLookup[srcChainId_];
        if (
            trustedRemote.length == 0 ||
            srcAddress_.length != trustedRemote.length ||
            keccak256(srcAddress_) != keccak256(trustedRemote)
        ) revert Bridge_InvalidMessageSource();

        // NOTE: Use low-level call to handle any errors. We trust the underlying receive
        // implementation, so we are doing a regular call vs using ExcessivelySafeCall
        (bool success, bytes memory reason) = address(this).call(
            abi.encodeWithSelector(
                this.receiveMessage.selector,
                srcChainId_,
                srcAddress_,
                nonce_,
                payload_
            )
        );

        // If message fails, store message for retry
        if (!success) {
            failedMessages[srcChainId_][srcAddress_][nonce_] = keccak256(payload_);
            emit MessageFailed(srcChainId_, srcAddress_, nonce_, payload_, reason);
        }
    }

    /// @notice Implementation of receiving an LZ message
    /// @dev    Function must be public to be called by low-level call in lzReceive
    function receiveMessage(
        uint16 srcChainId_,
        bytes memory srcAddress_,
        uint64 nonce_,
        bytes memory payload_
    ) public {
        // Needed to restrict access to low-level call from lzReceive
        if (msg.sender != address(this)) revert Bridge_InvalidCaller();
        _receiveMessage(srcChainId_, srcAddress_, nonce_, payload_);
    }

    /// @notice Retry a failed receive message
    function retryMessage(
        uint16 srcChainId_,
        bytes calldata srcAddress_,
        uint64 nonce_,
        bytes calldata payload_
    ) public payable virtual {
        // Assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId_][srcAddress_][nonce_];
        if (payloadHash == bytes32(0)) revert Bridge_NoStoredMessage();
        if (keccak256(payload_) != payloadHash) revert Bridge_InvalidPayload();

        // Clear the stored message
        failedMessages[srcChainId_][srcAddress_][nonce_] = bytes32(0);

        // Execute the message. revert if it fails again
        _receiveMessage(srcChainId_, srcAddress_, nonce_, payload_);

        emit RetryMessageSuccess(srcChainId_, srcAddress_, nonce_, payloadHash);
    }

    // ========= LZ Send Functions ========= //

    /// @notice Internal function for sending a message across chains.
    /// @dev    Params defined in ILayerZeroEndpoint `send` function.
    function _sendMessage(
        uint16 dstChainId_,
        bytes memory payload_,
        address payable refundAddress_,
        address zroPaymentAddress_,
        bytes memory adapterParams_,
        uint256 nativeFee_
    ) internal {
        bytes memory trustedRemote = trustedRemoteLookup[dstChainId_];
        if (trustedRemote.length == 0) revert Bridge_DestinationNotTrusted();

        // solhint-disable-next-line
        lzEndpoint.send{value: nativeFee_}(
            dstChainId_,
            trustedRemote,
            payload_,
            refundAddress_,
            zroPaymentAddress_,
            adapterParams_
        );
    }

    /// @notice Function to estimate how much gas is needed to send OHM
    /// @dev    Should be called by frontend before making sendOhm call.
    /// @return nativeFee - Native token amount to send to sendOhm
    /// @return zroFee - Fee paid in ZRO token. Unused.
    function estimateSendFee(
        uint16 dstChainId_,
        address to_,
        uint256 amount_,
        bytes calldata adapterParams_
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        // Mock the payload for sendOhm()
        bytes memory payload = abi.encode(to_, amount_);
        return lzEndpoint.estimateFees(dstChainId_, address(this), payload, false, adapterParams_);
    }

    // ========= LZ UserApplication & Admin config ========= //

    /// @notice Generic config for LayerZero User Application
    function setConfig(
        uint16 version_,
        uint16 chainId_,
        uint256 configType_,
        bytes calldata config_
    ) external override onlyRole("bridge_admin") {
        lzEndpoint.setConfig(version_, chainId_, configType_, config_);
    }

    /// @notice Set send version of endpoint to be used by LayerZero User Application
    function setSendVersion(uint16 version_) external override onlyRole("bridge_admin") {
        lzEndpoint.setSendVersion(version_);
    }

    /// @notice Set receive version of endpoint to be used by LayerZero User Application
    function setReceiveVersion(uint16 version_) external override onlyRole("bridge_admin") {
        lzEndpoint.setReceiveVersion(version_);
    }

    /// @notice Retries a received message. Used as last resort if retryPayload fails.
    /// @dev    Unblocks queue and DESTROYS transaction forever. USE WITH CAUTION.
    function forceResumeReceive(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external override onlyRole("bridge_admin") {
        lzEndpoint.forceResumeReceive(srcChainId_, srcAddress_);
    }

    /// @notice Sets the trusted path for the cross-chain communication
    /// @dev    path_ = abi.encodePacked(remoteAddress, localAddress)
    function setTrustedRemote(
        uint16 srcChainId_,
        bytes calldata path_
    ) external onlyRole("bridge_admin") {
        trustedRemoteLookup[srcChainId_] = path_;
        emit SetTrustedRemote(srcChainId_, path_);
    }

    /// @notice Convenience function for setting trusted paths between EVM addresses
    function setTrustedRemoteAddress(
        uint16 remoteChainId_,
        bytes calldata remoteAddress_
    ) external onlyRole("bridge_admin") {
        trustedRemoteLookup[remoteChainId_] = abi.encodePacked(remoteAddress_, address(this));
        emit SetTrustedRemoteAddress(remoteChainId_, remoteAddress_);
    }

    /// @notice Sets precrime address
    function setPrecrime(address precrime_) external onlyRole("bridge_admin") {
        precrime = precrime_;
        emit SetPrecrime(precrime_);
    }

    /// @notice Activate or deactivate the bridge
    function setBridgeStatus(bool isActive_) external onlyRole("bridge_admin") {
        bridgeActive = isActive_;
        emit BridgeStatusSet(isActive_);
    }

    // ========= View Functions ========= //

    /// @notice Gets endpoint config for this contract
    function getConfig(
        uint16 version_,
        uint16 chainId_,
        address,
        uint256 configType_
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(version_, chainId_, address(this), configType_);
    }

    /// @notice Get trusted remote for the given chain as an
    function getTrustedRemoteAddress(uint16 remoteChainId_) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[remoteChainId_];
        if (path.length == 0) revert Bridge_NoTrustedPath();

        // The last 20 bytes should be address(this)
        return path.slice(0, path.length - 20);
    }

    function isTrustedRemote(
        uint16 srcChainId_,
        bytes calldata srcAddress_
    ) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[srcChainId_];
        if (srcAddress_.length == 0 || trustedSource.length == 0)
            revert Bridge_TrustedRemoteUninitialized();
        return (srcAddress_.length == trustedSource.length &&
            keccak256(srcAddress_) == keccak256(trustedSource));
    }
}