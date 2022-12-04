// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IBridgeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract Bridgeable is IBridgeable
{
    bytes32 private constant BridgeInstructionFulfilledSlotPrefix = keccak256("SLOT:Bridgeable:bridgeInstructionFulfilled");

    bool public constant isBridgeable = true;
    bytes32 private constant bridgeInTypeHash = keccak256("BridgeIn(uint256 instructionId,address to,uint256 value)");

    function bridgeCanMint(address user) internal virtual view returns (bool);
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

    function bridgeIn(BridgeInstruction calldata instruction)
        public
    {
        uint256 status = bridgeInCore(instruction);
        if (status != 0) { throwStatus(status); }
    }

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

    function bridgeOut(address controller, uint256 value)
        public
    {
        if (value == 0) { revert ZeroAmount(); }
        if (controller == address(0)) { revert ZeroAddress(); }
        bridgeBurn(msg.sender, value);
        emit BridgeOut(msg.sender, controller, value);
    }
}