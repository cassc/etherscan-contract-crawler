// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IMessageLibManager.sol";
import "./IMessagingComposer.sol";
import "./IMessagingChannel.sol";
import "./IMessagingContext.sol";
import {Origin} from "../MessagingStructs.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint nativeFee;
    uint lzTokenFee;
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketDelivered(Origin origin, address receiver, bytes32 payloadHash);

    event PacketReceived(Origin origin, address receiver);

    event LzReceiveFailed(Origin origin, address receiver, bytes reason);

    event LayerZeroTokenSet(address token);

    function quote(
        address _sender,
        uint32 _dstEid,
        bytes calldata _message,
        bool _payInLzToken,
        bytes calldata _options
    ) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function sendWithAlt(
        MessagingParams calldata _params,
        uint _lzTokenFee,
        uint _altTokenFee
    ) external returns (MessagingReceipt memory);

    function deliver(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function deliverable(Origin calldata _origin, address _receiveLib, address _receiver) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable returns (bool, bytes memory);

    // oapp can burn messages partially by calling this function with its own business logic if messages are delivered in order
    function clear(Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLayerZeroToken(address _layerZeroToken) external;

    function layerZeroToken() external view returns (address);

    function altFeeToken() external view returns (address);
}