// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IMinterAgent} from "./IMinterAgent.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title MinterAgent
/// @notice Mints tokens on behalf of an account.  Meant to be cloned from the ZoraUniversalMinter span the life of a transaction, and be selfdestructed
contract MinterAgent is IMinterAgent, IERC1155Receiver, IERC721Receiver {
    address private owner;
    address private receiver;

    bytes4 constant ON_ERC1155_RECEIVED_HASH = IERC1155Receiver.onERC1155Received.selector;
    bytes4 constant ON_BATCH_ERC1155_RECEIVED_HASH = IERC1155Receiver.onERC1155BatchReceived.selector;
    bytes4 constant ON_ERC721_RECEIVED_HASH = IERC721Receiver.onERC721Received.selector;

    bytes constant emptyCalldata = "";

    /// @notice Initialize the agent with the receiver
    /// @param _owner - the owner of this contract, and the only one that can invoke forwardCall.  Typically the ZoraUniversalMinter
    /// @param _receiver - will be forwarded all tokens minted
    function initialize(address _owner, address _receiver) external {
        if (owner != address(0)) {
            revert ALREADY_INITIALIZED();
        }
        owner = _owner;
        receiver = _receiver;
    }

    /// Receive ERC1155 tokens and forward them to the receiver
    function onERC1155Received(address, address, uint256 id, uint256 value, bytes calldata) external returns (bytes4) {
        IERC1155(msg.sender).safeTransferFrom(address(this), receiver, id, value, emptyCalldata);
        return ON_ERC1155_RECEIVED_HASH;
    }

    /// Receive ERC1155 tokens and forward them to the receiver
    function onERC1155BatchReceived(address, address, uint256[] calldata ids, uint256[] calldata values, bytes calldata) external returns (bytes4) {
        IERC1155(msg.sender).safeBatchTransferFrom(address(this), receiver, ids, values, emptyCalldata);
        return ON_BATCH_ERC1155_RECEIVED_HASH;
    }

    /// Receive ERC721 tokens and forward them to the receiver
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        IERC721(msg.sender).safeTransferFrom(address(this), receiver, tokenId);
        return ON_ERC721_RECEIVED_HASH;
    }

    /// Calls a target contract from the agent.  Used to call minting functions.  Can be used to recover tokens or value locked at this address.
    /// Only callable by the owner, which should be the ZoraUniversalMinter
    /// @param _target target address
    /// @param _cd  calldata to send to the target contract
    /// @param _value Value to send to the target contract
    /// @return success if call succeeded
    /// @return data data returned from call
    function forwardCall(address _target, bytes calldata _cd, uint256 _value) external payable returns (bool success, bytes memory data) {
        if (msg.sender != owner) {
            revert ONLY_OWNER();
        }

        return _target.call{value: _value}(_cd);
    }

    bytes constant EMTPY_DATA = "";

    function forwardCallBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values
    ) external payable returns (bool success, bytes memory data) {
        if (msg.sender != owner) {
            revert ONLY_OWNER();
        }

        uint256 targetsLength = _targets.length;
        if (targetsLength == 0 || targetsLength != _calldatas.length || targetsLength != _values.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i = 0; i < targetsLength; i++) {
            // mint the fokens for each target contract.  These will be transferred to the msg.caller.
            (success, data) = _targets[i].call{value: _values[i]}(_calldatas[i]);

            // if any call fails, return false and the data from the failed call
            if (!success) {
                return (false, data);
            }
        }

        // if all calls succeeded, return true and the data from the last call
        success = true;
        data = EMTPY_DATA;
    }

    /// Needed to support the interface for the receiver
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    /// If for whatever reason this contract receives ETH (i.e. in the case of a refund to a minter agent) - just forward it back to the receiver
    receive() external payable {
        (bool success, ) = payable(receiver).call{value: msg.value}("");

        if (!success) revert("Failed to send");
    }
}