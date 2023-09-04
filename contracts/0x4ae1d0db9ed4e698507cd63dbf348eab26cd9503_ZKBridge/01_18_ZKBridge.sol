// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Governance.sol";
import "./libraries/external/RLPReader.sol";
import "./libraries/external/BytesLib.sol";
import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

contract ZKBridge is Governance, IZKBridgeEntrypoint {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;
    using BytesLib for bytes;

    bytes32 public constant MESSAGE_TOPIC = 0xb8abfd5c33667c7440a4fc1153ae39a24833dbe44f7eb19cbe5cd5f2583e4940;

    struct LogMessage {
        uint16 dstChainId;
        uint64 sequence;
        address dstAddress;
        bytes32 srcAddress;
        bytes32 srcZkBridge;
        bytes payload;
    }


    struct Payload {
        uint16 srcChainId;
        uint16 dstChainId;
        address srcAddress;
        address dstAddress;
        uint64 sequence;
        bytes uaPayload;
    }

    modifier initializer() {
        address implementation = ERC1967Upgrade._getImplementation();
        require(!isInitialized(implementation), "already initialized");
        _setInitialized(implementation);
        _;
    }

    function initialize() initializer public virtual {
        // this function needs to be exposed for an upgrade to pass
    }

    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64 sequence) {
        require(dstChainId != chainId(), "Cannot send to same chain");
        sequence = _useSequence(chainId(), msg.sender);
        payload = abi.encodePacked(bytes32("ZKBridge v2 version"), chainId(), dstChainId, msg.sender, dstAddress, sequence, payload);
        if (isL2()) {
            l2MessageSend().sendMessage{value : l2MessageSend().getFee()}(chainId(), msg.sender, dstChainId, dstAddress, sequence, payload);
        }
        emit MessagePublished(msg.sender, dstChainId, sequence, dstAddress, payload);
    }

    function sendFromL2(uint16 srcChainId,uint16 dstChainId, address dstAddress, bytes memory payload) external returns (uint64 sequence) {
        require(msg.sender == l2MessageReceive(srcChainId), "caller is not the l2MessageReceive");
        require(dstChainId != chainId(), "Cannot send to same chain");
        sequence = _useSequence(chainId(), msg.sender);
        emit MessagePublished(msg.sender, dstChainId, sequence, dstAddress, payload);
    }

    function validateTransactionProof(uint16 srcChainId, bytes32 srcBlockHash, uint256 logIndex, bytes memory mptProof) external {
        IMptVerifier mptVerifier = mptVerifier(srcChainId);
        IBlockUpdater blockUpdater = blockUpdater(srcChainId);
        require(address(mptVerifier) != address(0), "MptVerifier is not set");
        require(address(blockUpdater) != address(0), "Block Updater is not set");

        IMptVerifier.Receipt memory receipt = mptVerifier.validateMPT(mptProof);
        require(receipt.state == 1, "Source Chain Transaction Failure");

        require(blockUpdater.checkBlock(srcBlockHash, receipt.receiptHash), "Block Header is not set");

        LogMessage memory logMessage = _parseLog(receipt.logs, logIndex);
        require(logMessage.srcZkBridge == zkBridgeContracts(srcChainId), "Invalid source ZKBridge");
        require(logMessage.dstChainId == chainId(), "Invalid destination chain");
        bytes32 hash;
        hash = keccak256(abi.encode(srcChainId, logMessage.srcAddress, logMessage.sequence));
        require(!isTransferCompleted(hash), "Message already executed.");
        _setTransferCompleted(hash);
        emit ExecutedMessage(_truncateAddress(logMessage.srcAddress), srcChainId, logMessage.sequence, logMessage.dstAddress, logMessage.payload);
        (Payload memory p,bool isNewVersion) = _parsePayload(logMessage.payload);
        if (isNewVersion) {
            if (p.srcChainId != srcChainId) {
                require(p.dstChainId == chainId(), "Invalid destination chain");
                hash = keccak256(abi.encode(p.srcChainId, p.srcAddress, p.sequence));
                require(!isTransferCompleted(hash), "Message already executed.");
                _setTransferCompleted(hash);
                emit ExecutedMessage(p.srcAddress, p.srcChainId, p.sequence, p.dstAddress, p.uaPayload);
            }
            IZKBridgeReceiver(p.dstAddress).zkReceive(p.srcChainId, p.srcAddress, p.sequence, p.uaPayload);
        } else {
            IZKBridgeReceiver(logMessage.dstAddress).zkReceive(srcChainId, _truncateAddress(logMessage.srcAddress), logMessage.sequence, logMessage.payload);
        }
    }

    function validateTransactionFromL2(uint16 srcChainId, address srcAddress, address dstAddress, uint64 sequence, bytes calldata payload) external {
        require(msg.sender == l2MessageReceive(srcChainId), "caller is not the l2MessageReceive");
        (Payload memory p,bool isNewVersion) = _parsePayload(payload);
        require(isNewVersion, "Unsupported version");
        require(srcChainId == p.srcChainId, "Invalid srcChainId");
        require(p.dstChainId == chainId(), "Invalid destination chain");
        bytes32 hash = keccak256(abi.encode(srcChainId, srcAddress, sequence));
        require(!isTransferCompleted(hash), "Message already executed.");
        _setTransferCompleted(hash);

        IZKBridgeReceiver(dstAddress).zkReceive(srcChainId, srcAddress, sequence, p.uaPayload);
        emit ExecutedMessage(srcAddress, srcChainId, sequence, dstAddress, payload);
    }

    function _useSequence(uint16 chainId, address emitter) internal returns (uint64 sequence) {
        bytes32 hash = keccak256(abi.encode(chainId, emitter));
        sequence = nextSequence(hash);
        _setNextSequence(hash, sequence + 1);
    }

    function _parseLog(bytes memory logsByte, uint256 logIndex) internal pure returns (LogMessage memory logMessage) {
        RLPReader.RLPItem[] memory logs = logsByte.toRlpItem().toList();
        if (logIndex != 0) {
            logs = logs[logIndex + 2].toRlpBytes().toRlpItem().toList();
        }
        RLPReader.RLPItem[] memory topicItem = logs[1].toRlpBytes().toRlpItem().toList();
        bytes32 topic = abi.decode(topicItem[0].toBytes(), (bytes32));
        if (topic == MESSAGE_TOPIC) {
            logMessage.srcZkBridge = logs[0].toBytes32();
            logMessage.srcAddress = abi.decode(topicItem[1].toBytes(), (bytes32));
            logMessage.dstChainId = abi.decode(topicItem[2].toBytes(), (uint16));
            logMessage.sequence = abi.decode(topicItem[3].toBytes(), (uint64));
            (logMessage.dstAddress, logMessage.payload) = abi.decode(logs[2].toBytes(), (address, bytes));
        }
    }

    function _parsePayload(bytes memory payload) internal pure returns (Payload memory txPayload, bool isNewVersion) {
        uint index = 0;

        bytes32 tag = payload.toBytes32(index);
        if (tag != bytes32("ZKBridge v2 version")) {
            return (txPayload, isNewVersion);
        }
        index += 32;

        txPayload.srcChainId = payload.toUint16(index);
        index += 2;

        txPayload.dstChainId = payload.toUint16(index);
        index += 2;

        txPayload.srcAddress = payload.toAddress(index);
        index += 20;

        txPayload.dstAddress = payload.toAddress(index);
        index += 20;

        txPayload.sequence = payload.toUint64(index);
        index += 8;
        txPayload.uaPayload = payload.slice(index, payload.length - index);

        isNewVersion = true;
    }

    function _truncateAddress(bytes32 b) internal pure returns (address) {
        require(bytes12(b) == 0, "invalid EVM address");
        return address(uint160(uint256(b)));
    }

    fallback() external payable {revert("unsupported");}

    receive() external payable {revert("the ZkBridge contract does not accept assets");}
}