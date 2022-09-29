//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "./lib/SSCVault.sol";
import "./lib/Assertions.sol";

contract MSSC is SSCVault, AccessControl, ReentrancyGuard {
    // Events
    event RegisterCycle(bytes32 indexed cycleId, Instruction[] instructions);
    event ExecuteCycle(bytes32 indexed cycleId, bytes32[] instructions);

    bytes32 public constant MEMBRANE_ROLE = keccak256("MEMBRANE");

    mapping(bytes32 => SettlementCycle) private _cycles;
    mapping(bytes32 => Instruction) private _instructions;

    constructor() payable {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MEMBRANE_ROLE, _msgSender());
    }

    /**
     * @notice Register settlementCycle, this function can only be perfomed by a Membrane wallet.
     *         Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param cycleId Cycle's bytes32 obfuscatedId to register.
     * @param instructions instructions to register.
     */
    function registerSettlementCycle(
        bytes32 cycleId,
        Instruction[] calldata instructions
    ) external onlyRole(MEMBRANE_ROLE) {
        _assertCycleDoesNotExist(cycleId);
        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        if (totalInstructions == 0) {
            revert CycleHasNoInstruction();
        }

        bytes32[] storage newInstructions = _cycles[cycleId].instructions;

        for (uint256 i = 0; i < totalInstructions; ) {
            Instruction memory instruction = instructions[i];
            bytes32 instructionId = instruction.id;

            _assertValidInstruction(instruction);

            newInstructions.push(instructionId);
            _instructions[instructionId] = instruction;

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }

        emit RegisterCycle(cycleId, instructions);
    }

    /**
     * @notice Execute instructions in a SettlementCycle, anyone can call this function as long as it
     *         meets some requirements.
     *
     * @param cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeInstructions(bytes32 cycleId) external nonReentrant {
        _assertCycleExists(cycleId);

        _assertCycleIsNotExecuted(cycleId);

        _cycles[cycleId].executed = true;
        bytes32[] memory instructions = _cycles[cycleId].instructions;

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        for (uint256 i = 0; i < totalInstructions; ) {
            Instruction memory instruction = _instructions[instructions[i]];

            DepositItem memory depositItem = _buildDepositItem(instruction);

            _withdrawTo(depositItem, instruction.receiver);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
        emit ExecuteCycle(cycleId, instructions);
    }

    /**
     * @notice Make deposits (Native coin or ERC20 tokens) to a existent instruction, {msg.sender} will become
     *         the {sender} of the instruction hence will be the only account which is able to withdraw
     *         those allocated funds.
     *
     * @param instructionId Instruction to allocate funds.
     */
    function deposit(bytes32 instructionId) external payable nonReentrant {
        Instruction memory instruction = _instructions[instructionId];
        uint256 amount = instruction.amount;
        // Ensure that instruction does exist by checking its amount.
        if (amount == 0) {
            revert NoInstruction(instructionId);
        }

        DepositItem memory depositItem = _buildDepositItem(instruction);

        _deposit(depositItem, amount);
    }

    /**
     * @notice Withdraw funds from a settlement. Caller must be the sender of instruction.
     *
     * @param instructionId Instruction to withdraw deposited funds from.
     */
    function withdraw(bytes32 instructionId) external nonReentrant {
        DepositItem memory depositItem = _buildDepositItem(
            _instructions[instructionId]
        );
        _withdraw(depositItem);
    }

    /**
     * @notice View function to get the instructions ids in a settlement cycle.
     *
     * @param cycleId Cycle to check.
     */
    function getSettlementInstructions(bytes32 cycleId)
        external
        view
        returns (bytes32[] memory)
    {
        _assertCycleExists(cycleId);
        return _cycles[cycleId].instructions;
    }

    /**
     * @notice View function to check if a cycle has been registered.
     *
     * @param cycleId Cycle to check.
     */
    function registered(bytes32 cycleId) external view returns (bool) {
        return _exist(cycleId);
    }

    /**
     * @notice View function to check if a cycle has been executed.
     *
     * @param cycleId Cycle to check.
     */
    function executed(bytes32 cycleId) external view returns (bool) {
        _assertCycleExists(cycleId);
        return _cycles[cycleId].executed;
    }

    /**
     * @notice View function to get deposited funds to an instruction.
     *
     * @param instructionId Instruction to get deposited funds from.
     */
    function deposits(bytes32 instructionId) external view returns (uint256) {
        return _deposits[instructionId];
    }

    /**
     * @notice View function to get sender of a instruction.
     *
     * @param instructionId Instruction to get the sender.
     */
    function senderOf(bytes32 instructionId) external view returns (address) {
        return _senderOf[instructionId];
    }

    /*//////////////////////////////////////////////////////////////
                             ASSERTIONS
    //////////////////////////////////////////////////////////////*/

    // Check if an address is a sender of any instruction in the instruction.

    // Ensure that {cycleId} is registered.
    function _assertCycleExists(bytes32 cycleId) private view {
        if (!_exist(cycleId)) {
            revert NoCycle();
        }
    }

    // Ensure that {cycleId} is NOT registered.
    function _assertCycleDoesNotExist(bytes32 cycleId) private view {
        if (_exist(cycleId)) {
            revert CycleAlreadyRegistered();
        }
    }

    // Ensure that cycle hasn't been executed before.
    function _assertCycleIsNotExecuted(bytes32 cycleId) private view {
        if (_cycles[cycleId].executed) {
            revert CycleAlreadyExecuted();
        }
    }

    // Validate Instruction
    function _assertValidInstruction(Instruction memory instruction)
        private
        view
    {
        // Ensure that instruction doesn't exist by checking its amount.
        if (_instructions[instruction.id].amount > 0) {
            revert InstructionExists(instruction.id);
        }

        _assertValidInstructionData(instruction);
    }

    // Check that cycleId is registered by looking at instructions length, this function may change its logic later
    function _exist(bytes32 cycleId) private view returns (bool) {
        return _cycles[cycleId].instructions.length > 0;
    }

    // Build Deposit item from instruction
    function _buildDepositItem(Instruction memory instruction)
        private
        pure
        returns (DepositItem memory)
    {
        return
            DepositItem({
                depositType: instruction.asset == address(0)
                    ? DepositType.NATIVE
                    : DepositType.ERC20,
                token: instruction.asset,
                instructionId: instruction.id
            });
    }
}