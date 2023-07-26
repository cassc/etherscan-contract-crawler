// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./dependencies/@layerzerolabs/solidity-examples/lzApp/NonblockingLzApp.sol";
import {BytesLib} from "../contracts/dependencies/@layerzerolabs/solidity-examples/util/BytesLib.sol";
// import "../lib/forge-std/src/console.sol";


contract PingPong is NonblockingLzApp {
    using BytesLib for bytes;
    // packet type
    uint16 internal constant PT_SEND_AND_CALL = 1;

    // See more: https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters
    uint16 internal constant LZ_ADAPTER_PARAMS_VERSION_2 = 2;

    uint16 internal constant LZ_ADAPTER_PARAMS_VERSION_1 = 1;

    uint256 internal constant PING_GAS = 700_000;

    uint256 internal constant CALLBACK_GAS = 600_000;

    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress);


    // constructor requires the LayerZero endpoint for this chain
    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    // allow this contract to receive ether
    receive() external payable {}

    struct PingStatus {
        bool sent;
        bool receivedCallback;
    }

    mapping(uint256 => PingStatus) public sent;
    mapping(uint256 => bool) public received;
    uint256 public nonce;

    function estimatePingFee(
        uint16 _dstChainId,
        uint256 _callBackNativeFee
    ) external view virtual returns (uint nativeFee, uint zroFee) {
        bytes memory _adapterParams = abi.encodePacked(
            LZ_ADAPTER_PARAMS_VERSION_2,
            PING_GAS,
            _callBackNativeFee,
            trustedRemoteLookup[_dstChainId]
        );
        bytes memory payload = abi.encode(type(uint256).max);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, _adapterParams);
    }

    // pings the destination chain. When destination chain receive message it send back callback to this chain gain
    // Caller must send msg.value higher than gas consumed to execute method on
    // _dstChainId + callback on this chain
    function ping(uint16 _dstChainId, uint256 _callbackTxNativeFee) public payable {
        require(address(this).balance > 0, "the balance of this contract is 0. pls send gas for message fees");
        PingStatus storage _status = sent[++nonce];
        _status.sent = true;
        // encode the payload with the number of pings
        bytes memory payload = abi.encode(nonce);
        bytes memory adapterParams = abi.encodePacked(
            LZ_ADAPTER_PARAMS_VERSION_2,
            PING_GAS,
            _callbackTxNativeFee,
            (this.trustedRemoteLookup(_dstChainId)).toAddress(0)
        );

        // send LayerZero message
        _lzSend( // {value: messageFee} will be paid out of this contract!
            _dstChainId, // destination chainId
            payload, // abi.encode()'ed bytes
            payable(msg.sender), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send()
            address(0x0), // future param, unused for this example
            adapterParams, // v1 adapterParams, specify custom destination gas qty
            msg.value
        );
        emit SendToChain(_dstChainId, address(this), this.trustedRemoteLookup(_dstChainId));
    }

    function estimateCallbackFee(uint16 _dstChainId) public view virtual returns (uint nativeFee, uint zroFee) {
        bytes memory _adapterParams = abi.encodePacked(LZ_ADAPTER_PARAMS_VERSION_1, uint256(CALLBACK_GAS));
        bytes memory payload = abi.encode(type(uint256).max);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, _adapterParams);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory, // _srcAddress. Unused
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        // decode the number of pings sent thus far
        console.log("received");
        uint _messageId = abi.decode(_payload, (uint256));
        PingStatus storage _status = sent[_messageId];
        console.log("_messageId", _messageId, _status.sent);
        console.log("sent", _status.sent);
        if (_status.sent) {
            // message was originated from here
            _status.receivedCallback = true;
        } else {
            // message originated from other chain
            received[_messageId] = true;
            // use adapterParams v1 to specify more gas for the destination
            bytes memory adapterParams = abi.encodePacked(LZ_ADAPTER_PARAMS_VERSION_1, CALLBACK_GAS);
            (uint256 callbackNativeFee, ) = estimateCallbackFee(_srcChainId);
            // send LayerZero message
            _lzSend( // {value: messageFee} will be paid out of this contract!
                _srcChainId, // destination chainId
                _payload, // abi.encode()'ed bytes
                payable(msg.sender), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send()
                address(0x0), // future param, unused for this example
                adapterParams, // v1 adapterParams, specify custom destination gas qty
                callbackNativeFee
            );
            emit SendToChain(_srcChainId, address(this), this.trustedRemoteLookup(_srcChainId));
        }
    }
}