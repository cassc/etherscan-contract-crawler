// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mailer
/// @notice An example contract for sending messages to other chains, using the ZKBridgeEntrypoint.
contract LzMailer is Ownable {
    /// @notice The ZKBridgeEntrypoint contract, which sends messages to other chains.
    IZKBridgeEntrypoint public zkBridgeEntrypoint;

    ILayerZeroEndpoint public immutable lzEndpoint;

    bool public zkBridgePaused = false;
    bool public layerZeroPaused = false;

    uint256 public maxLength = 200;

    /// @notice Fee for each chain.
    mapping(uint16 => uint256) public fees;

    event MessageSend(
        uint64 indexed sequence,
        uint32 indexed dstChainId,
        address indexed dstAddress,
        address sender,
        address recipient,
        string message
    );

    event LzMessageSend(
        uint64 indexed sequence,
        uint32 indexed dstChainId,
        address indexed dstAddress,
        address sender,
        address recipient,
        string message
    );
    event NewFee(uint16 chainId, uint256 fee);
    /// @notice Event emitted when an action is paused/unpaused
    event PauseSendAction(
        address account,
        bool zkBridgePaused,
        bool layerZeroPaused
    );

    constructor(address _zkBridgeEntrypoint, address _lzEndpoint) {
        zkBridgeEntrypoint = IZKBridgeEntrypoint(_zkBridgeEntrypoint);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    /// @notice Sends a message to a destination MessageBridge.
    /// @param dstChainId The chain ID where the destination MessageBridge.
    /// @param dstAddress The address of the destination MessageBridge.
    /// @param recipient Recipient of the target chain message.
    /// @param message The message to send.
    function sendMessage(
        uint16 dstChainId,
        address dstAddress,
        uint16 lzChainId,
        address lzDstAddress,
        uint256 nativeFee,
        address recipient,
        string memory message
    ) external payable {
        if (layerZeroPaused && zkBridgePaused) {
            revert("Nothing to do");
        }

        uint256 zkFee = fees[dstChainId];
        if (zkBridgePaused) {
            zkFee = 0;
        }

        if (layerZeroPaused) {
            require(nativeFee == 0, "Invalid native fee");
        }
        require(msg.value >= nativeFee + zkFee, "Insufficient Fee");
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        if (!zkBridgePaused) {
            _sendMessage(dstChainId, dstAddress, recipient, message);
        }

        if (!layerZeroPaused) {
            _sendToLayerZero(
                lzChainId,
                lzDstAddress,
                recipient,
                nativeFee,
                message
            );
        }
    }

    function zkSendMessage(
        uint16 dstChainId,
        address dstAddress,
        address recipient,
        string memory message
    ) external payable {
        if (zkBridgePaused) {
            revert("Paused");
        }
        require(msg.value >= fees[dstChainId], "Insufficient Fee");
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        _sendMessage(dstChainId, dstAddress, recipient, message);
    }

    function lzSendMessage(
        uint16 lzChainId,
        address lzDstAddress,
        address recipient,
        string memory message
    ) external payable {
        if (layerZeroPaused) {
            revert("Paused");
        }
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        _sendToLayerZero(
            lzChainId,
            lzDstAddress,
            recipient,
            msg.value,
            message
        );
    }

    function _sendMessage(
        uint16 dstChainId,
        address dstAddress,
        address recipient,
        string memory message
    ) private {
        bytes memory payload = abi.encode(msg.sender, recipient, message);
        uint64 _sequence = zkBridgeEntrypoint.send(
            dstChainId,
            dstAddress,
            payload
        );
        emit MessageSend(
            _sequence,
            dstChainId,
            dstAddress,
            msg.sender,
            recipient,
            message
        );
    }

    function _sendToLayerZero(
        uint16 _dstChainId,
        address _dstAddress,
        address _recipient,
        uint256 _nativeFee,
        string memory _message
    ) private {
        bytes memory payload = abi.encode(msg.sender, _recipient, _message);
        bytes memory path = abi.encodePacked(_dstAddress, address(this));

        lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            path,
            payload,
            payable(msg.sender),
            msg.sender,
            bytes("")
        );

        uint64 _sequence = lzEndpoint.outboundNonce(_dstChainId, address(this));

        emit LzMessageSend(
            _sequence,
            _dstChainId,
            _dstAddress,
            msg.sender,
            _recipient,
            _message
        );
    }

    /// @notice Allows owner to set a new msg length.
    /// @param _maxLength new msg length.
    function setMsgLength(uint256 _maxLength) external onlyOwner {
        maxLength = _maxLength;
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    /// @notice Allows owner to set a new fee.
    /// @param _dstChainId The chain ID where the destination MessageBridge.
    /// @param _fee The new fee to use.
    function setFee(uint16 _dstChainId, uint256 _fee) external onlyOwner {
        require(fees[_dstChainId] != _fee, "Fee has already been set.");
        fees[_dstChainId] = _fee;
        emit NewFee(_dstChainId, _fee);
    }

    /**
     * @notice Pauses different actions
     * @dev Changes the owner address.
     * @param zkBridgePaused_ Boolean for zkBridge send
     * @param layerZeroPaused_ Boolean for layer zero send
     */
    function pause(
        bool zkBridgePaused_,
        bool layerZeroPaused_
    ) external onlyOwner {
        zkBridgePaused = zkBridgePaused_;
        layerZeroPaused = layerZeroPaused_;
        emit PauseSendAction(msg.sender, zkBridgePaused, layerZeroPaused);
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function estimateLzFee(
        uint16 _dstChainId,
        address _recipient,
        string memory _message
    ) public view returns (uint256 nativeFee) {
        if (layerZeroPaused) {
            return 0;
        }

        bytes memory payload = abi.encode(msg.sender, _recipient, _message);
        (nativeFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            bytes("")
        );
    }

    /**
     * @notice set the configuration of the LayerZero messaging library of the specified version
     * @param _version - messaging library version
     * @param _dstChainId - the chainId for the pending config change
     * @param _configType - type of configuration. every messaging library has its own convention.
     * @param _config - configuration in the bytes. can encode arbitrary content.
     */
    function setConfig(
        uint16 _version,
        uint16 _dstChainId,
        uint _configType,
        bytes calldata _config
    ) external onlyOwner {
        lzEndpoint.setConfig(_version, _dstChainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /// @notice get the send() LayerZero messaging library version
    function getSendVersion() external view returns (uint16) {
        return lzEndpoint.getSendVersion(address(this));
    }

    /**
     * @notice get the configuration of the LayerZero messaging library of the specified version
     * @param _version - messaging library version
     * @param _dstChainId - the chainId for the pending config change
     * @param _configType - type of configuration. every messaging library has its own convention.
     */
    function getConfig(
        uint16 _version,
        uint16 _dstChainId,
        uint _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                _version,
                _dstChainId,
                address(this),
                _configType
            );
    }
}