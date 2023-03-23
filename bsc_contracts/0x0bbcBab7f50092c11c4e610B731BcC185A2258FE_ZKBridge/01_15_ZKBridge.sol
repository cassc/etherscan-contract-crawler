// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Governance.sol";
import "./libraries/external/RLPReader.sol";
import "./interfaces/IZKBridge.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

contract ZKBridge is Governance, IZKBridge {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    bytes32 public constant MESSAGE_TOPIC = 0xb8abfd5c33667c7440a4fc1153ae39a24833dbe44f7eb19cbe5cd5f2583e4940;

    struct LogMessage {
        uint16 dstChainId;
        uint64 sequence;
        address dstAddress;
        bytes32 srcAddress;
        bytes32 srcZkBridge;
        bytes payload;
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
        bytes32 hash = keccak256(abi.encode(srcChainId, logMessage.srcAddress, logMessage.sequence));
        require(!isTransferCompleted(hash), "Message already executed.");
        _setTransferCompleted(hash);

        address srcAddress = _truncateAddress(logMessage.srcAddress);
        IZKBridgeReceiver(logMessage.dstAddress).zkReceive(srcChainId, srcAddress, logMessage.sequence, logMessage.payload);
        emit ExecutedMessage(srcAddress, srcChainId, logMessage.sequence, logMessage.dstAddress, logMessage.payload);
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

    function _truncateAddress(bytes32 b) internal pure returns (address) {
        require(bytes12(b) == 0, "invalid EVM address");
        return address(uint160(uint256(b)));
    }

    fallback() external payable {revert("unsupported");}

    receive() external payable {revert("the ZkBridge contract does not accept assets");}
}