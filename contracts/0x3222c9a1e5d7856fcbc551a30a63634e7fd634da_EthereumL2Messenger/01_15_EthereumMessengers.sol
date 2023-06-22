// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../../interfaces/IMessenger.sol";
import "../../RestrictedCalls.sol";
import "../../Resolver.sol";

contract EthereumL1Messenger is IMessenger, RestrictedCalls {
    function callAllowed(address, address) external pure returns (bool) {
        // The call must be delivered by the Resolver
        // Since we are on the same chain as the Resolver
        // we should never see an execution of this function.
        revert("Unexpected call to callAllowed");
    }

    // Simply forward the message to the target on L1
    function sendMessage(
        address target,
        bytes calldata message
    ) external restricted(block.chainid) {
        (bool sent, ) = target.call(message);
        require(sent, "sending message failed");
    }
}

// In order to keep naming consistent between our rollup specific contracts
// we are using `EthereumL2Messenger` here as a name even if this contract
// is supposed to be deployed on L1.
contract EthereumL2Messenger is IMessenger, RestrictedCalls {
    enum MessageStatus {
        UNDEFINED,
        DEFINED,
        RELAYED
    }

    Resolver public immutable resolver;

    /// Maps message hashes to their status.
    mapping(bytes32 messageHash => MessageStatus) public messageHashes;

    constructor(address resolver_) {
        resolver = Resolver(resolver_);
    }

    function callAllowed(address, address) external pure returns (bool) {
        // Since we are on the same chain as the FillManager & RequestManager
        // we should never see an execution of this function.
        revert("Unexpected call to callAllowed");
    }

    // Store message instead of forwarding it.
    // Can be forwarded, if ever needed, by calling `relayMessage`.
    //
    // .. seealso:: :sol:func:`relayMessage`
    function sendMessage(
        address,
        bytes calldata message
    ) external restricted(block.chainid) {
        bytes32 messageHash = keccak256(message);

        require(
            messageHashes[messageHash] != MessageStatus.DEFINED,
            "Message is already registered"
        );
        require(
            messageHashes[messageHash] != MessageStatus.RELAYED,
            "Message has already been relayed"
        );

        messageHashes[messageHash] = MessageStatus.DEFINED;
    }

    function relayMessage(
        bytes32 requestId,
        bytes32 fillId,
        uint256 sourceChainId,
        address filler
    ) external {
        bytes memory message = abi.encodeCall(
            Resolver.resolve,
            (requestId, fillId, block.chainid, sourceChainId, filler)
        );
        bytes32 messageHash = keccak256(message);

        require(
            messageHashes[messageHash] != MessageStatus.UNDEFINED,
            "Message not yet registered"
        );
        require(
            messageHashes[messageHash] != MessageStatus.RELAYED,
            "Message has already been relayed"
        );

        messageHashes[messageHash] = MessageStatus.RELAYED;

        (bool sent, ) = address(resolver).call(message);
        require(sent, "relaying message failed");
    }
}