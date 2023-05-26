// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mailer
/// @notice An example contract for sending messages to other chains, using the ZKBridgeEntrypoint.
contract Mailer is Ownable {
    /// @notice The ZKBridgeEntrypoint contract, which sends messages to other chains.
    IZKBridgeEntrypoint public zkBridgeEntrypoint;

    uint256 public fee;

    event MessageSend(uint64 indexed sequence, uint32 indexed dstChainId, address indexed dstAddress, address sender, address recipient, string message);

    constructor(address zkBridgeEntrypointAddress) {
        zkBridgeEntrypoint = IZKBridgeEntrypoint(zkBridgeEntrypointAddress);
    }

    /// @notice Sends a message to a destination MessageBridge.
    /// @param dstChainId The chain ID where the destination MessageBridge.
    /// @param dstAddress The address of the destination MessageBridge.
    /// @param message The message to send.
    function sendMessage(uint16 dstChainId, address dstAddress, address recipient, string memory message) external payable {
        require(msg.value >= fee, "Insufficient Fee");
        bytes memory payload = abi.encode(msg.sender, recipient, message);
        uint64 sequence = zkBridgeEntrypoint.send(dstChainId, dstAddress, payload);
        emit MessageSend(sequence, dstChainId, dstAddress,msg.sender, recipient,message);
    }

    // @notice Allows owner to set a new fee.
    // @param fee The new fee to use.
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}