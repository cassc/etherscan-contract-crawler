// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IBridgeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Implements cross-chain bridging functionality (for our purposes, in an ERC20)

    The bridge (an off-chain process) can sign instructions for minting, which users can submit to the blockchain.

    Users can also send funds to the bridge, which can be detected by the bridge processor looking for "BridgeOut" events
 */
abstract contract Bridgeable is IBridgeable
{
    bytes32 private constant BridgeInstructionFulfilledSlotPrefix = keccak256("SLOT:Bridgeable:bridgeInstructionFulfilled");

    bool public constant isBridgeable = true;
    bytes32 private constant bridgeInTypeHash = keccak256("BridgeIn(uint256 instructionId,address to,uint256 value)");

    // A fully constructed contract would likely use "Minter" contract functions to implement this
    function bridgeCanMint(address user) internal virtual view returns (bool);
    // A fully constructed contract would likely use "RERC20" contract functions to implement these
    function bridgeSigningHash(bytes32 dataHash) internal virtual view returns (bytes32);
    function bridgeMint(address to, uint256 amount) internal virtual;
    function bridgeBurn(address from, uint256 amount) internal virtual;

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IBridgeable(newImplementation).isBridgeable());
    }

    function bridgeInstructionFulfilled(uint256 instructionId)
        public
        view
        returns (bool)
    {
        return StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instructionId))).value;
    }

    function throwStatus(uint256 status)
        private
        pure
    {
        if (status == 1) { revert ZeroAmount(); }
        if (status == 2) { revert InvalidBridgeSignature(); }
        if (status == 3) { revert DuplicateInstruction(); }
    }

    /** Returns 0 on success */
    function bridgeInCore(BridgeInstruction calldata instruction)
        private
        returns (uint256)
    {
        if (instruction.value == 0) { return 1; }
        if (!bridgeCanMint(
                ecrecover(
                    bridgeSigningHash(
                        keccak256(
                            abi.encode(
                                bridgeInTypeHash, 
                                instruction.instructionId,
                                instruction.to, 
                                instruction.value))),
                instruction.v,
                instruction.r,
                instruction.s))) 
        {
            return 2;
        }
        StorageSlot.BooleanSlot storage fulfilled = StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instruction.instructionId)));
        if (fulfilled.value) { return 3; }
        fulfilled.value = true;
        bridgeMint(instruction.to, instruction.value);
        emit BridgeIn(instruction.instructionId, instruction.to, instruction.value);
        return 0;
    }

    /** Mints according to the bridge instruction, or reverts on failure */
    function bridgeIn(BridgeInstruction calldata instruction)
        public
    {
        uint256 status = bridgeInCore(instruction);
        if (status != 0) { throwStatus(status); }
    }

    /** Mints according to multiple bridge instructions.  Only reverts if no instructions succeeded */
    function multiBridgeIn(BridgeInstruction[] calldata instructions)
        public
    {
        bool anySuccess = false;
        uint256 status = 0;
        for (uint256 x = instructions.length; x > 0;) 
        {
            unchecked { --x; }
            status = bridgeInCore(instructions[x]);
            if (status == 0) { anySuccess = true; }
        }
        if (!anySuccess) 
        {
            throwStatus(status); 
            revert ZeroArray();
        }
    }

    /** Sends funds to the bridge */
    function bridgeOut(address controller, uint256 value)
        public
    {
        if (value == 0) { revert ZeroAmount(); }
        if (controller == address(0)) { revert ZeroAddress(); }
        bridgeBurn(msg.sender, value);
        emit BridgeOut(msg.sender, controller, value);
    }
}