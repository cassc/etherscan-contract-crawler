// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IDecapacitor.sol";
import "../interfaces/IPlug.sol";

import "./SocketBase.sol";

abstract contract SocketDst is SocketBase {
    error AlreadyAttested();
    error InvalidProof();
    error InvalidRetry();
    error MessageAlreadyExecuted();
    error NotExecutor();
    error VerificationFailed();

    // srcChainSlug => switchboardAddress => executorAddress => fees
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public feesEarned;
    // msgId => message status
    mapping(uint256 => bool) public messageExecuted;
    // capacitorAddr|chainSlug|packetId
    mapping(uint256 => bytes32) public override remoteRoots;
    mapping(uint256 => uint256) public rootProposedAt;

    /**
     * @notice emits the packet details when proposed at remote
     * @param transmitter address of transmitter
     * @param packetId packet id
     * @param root packet root
     */
    event PacketProposed(
        address indexed transmitter,
        uint256 indexed packetId,
        bytes32 root
    );

    /**
     * @notice emits the root details when root is replaced by owner
     * @param packetId packet id
     * @param oldRoot old root
     * @param newRoot old root
     */
    event PacketRootUpdated(uint256 packetId, bytes32 oldRoot, bytes32 newRoot);

    function propose(
        uint256 packetId_,
        bytes32 root_,
        bytes calldata signature_
    ) external {
        if (remoteRoots[packetId_] != bytes32(0)) revert AlreadyAttested();
        (address transmitter, bool isTransmitter) = transmitManager__
            .checkTransmitter(
                (_getChainSlug(packetId_) << 128) | chainSlug,
                packetId_,
                root_,
                signature_
            );
        if (!isTransmitter) revert InvalidAttester();

        remoteRoots[packetId_] = root_;
        rootProposedAt[packetId_] = block.timestamp;

        emit PacketProposed(transmitter, packetId_, root_);
    }

    /**
     * @notice executes a message
     * @param packetId_ packet id
     * @param localPlug_ remote plug address
     * @param messageDetails_ the details needed for message verification
     */
    function execute(
        uint256 packetId_,
        address localPlug_,
        ISocket.MessageDetails calldata messageDetails_
    ) external override {
        if (!executionManager__.isExecutor(msg.sender)) revert NotExecutor();
        if (messageExecuted[messageDetails_.msgId])
            revert MessageAlreadyExecuted();
        messageExecuted[messageDetails_.msgId] = true;

        uint256 remoteSlug = uint256(messageDetails_.msgId >> 224);

        PlugConfig storage plugConfig = _plugConfigs[
            (uint256(uint160(localPlug_)) << 96) | remoteSlug
        ];

        feesEarned[remoteSlug][address(plugConfig.inboundSwitchboard__)][
            msg.sender
        ] += messageDetails_.executionFee;

        bytes32 packedMessage = hasher__.packMessage(
            remoteSlug,
            plugConfig.siblingPlug,
            chainSlug,
            localPlug_,
            messageDetails_.msgId,
            messageDetails_.msgGasLimit,
            messageDetails_.executionFee,
            messageDetails_.payload
        );

        _verify(
            packetId_,
            remoteSlug,
            packedMessage,
            plugConfig,
            messageDetails_.decapacitorProof
        );
        _execute(
            localPlug_,
            remoteSlug,
            messageDetails_.msgGasLimit,
            messageDetails_.msgId,
            messageDetails_.payload
        );
    }

    function _verify(
        uint256 packetId_,
        uint256 remoteChainSlug_,
        bytes32 packedMessage_,
        PlugConfig storage plugConfig_,
        bytes memory decapacitorProof_
    ) internal view {
        if (
            !ISwitchboard(plugConfig_.inboundSwitchboard__).allowPacket(
                remoteRoots[packetId_],
                packetId_,
                remoteChainSlug_,
                rootProposedAt[packetId_]
            )
        ) revert VerificationFailed();

        if (
            !plugConfig_.decapacitor__.verifyMessageInclusion(
                remoteRoots[packetId_],
                packedMessage_,
                decapacitorProof_
            )
        ) revert InvalidProof();
    }

    function _execute(
        address localPlug_,
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        uint256 msgId_,
        bytes calldata payload_
    ) internal {
        try
            IPlug(localPlug_).inbound{gas: msgGasLimit_}(
                remoteChainSlug_,
                payload_
            )
        {
            emit ExecutionSuccess(msgId_);
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            messageExecuted[msgId_] = false;
            emit ExecutionFailed(msgId_, reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            messageExecuted[msgId_] = false;
            emit ExecutionFailedBytes(msgId_, reason);
        }
    }

    /**
     * @notice updates root for given packet id
     * @param packetId_ id of packet to be updated
     * @param newRoot_ new root
     */
    function updatePacketRoot(
        uint256 packetId_,
        bytes32 newRoot_
    ) external onlyOwner {
        bytes32 oldRoot = remoteRoots[packetId_];
        remoteRoots[packetId_] = newRoot_;

        emit PacketRootUpdated(packetId_, oldRoot, newRoot_);
    }

    function isPacketProposed(uint256 packetId_) external view returns (bool) {
        return remoteRoots[packetId_] == bytes32(0) ? false : true;
    }

    function _getChainSlug(
        uint256 packetId_
    ) internal pure returns (uint256 chainSlug_) {
        chainSlug_ = uint32(packetId_ >> 224);
    }
}