// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/MSSCErrors.sol";
import "./SSCStructs.sol";

/**
 * @title Assertions
 * @notice Assertions contains logic for making various assertions that do not
 *         fit neatly within a dedicated semantic scope.
 */
contract Assertions is MSSCErrors {
    /**
     * @dev Internal view function to ensure that a given instruction tuple has valid data.
     *
     * @param instruction  The instruction tuple to check.
     */

    function _assertValidInstructionData(Instruction memory instruction)
        internal
        view
    {
        _assertNonZeroAmount(instruction.amount, instruction.id);

        _assertReceiverIsNotZeroAddress(instruction);

        _assertValidAsset(instruction);
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount, bytes32 instructionId) internal pure {
        // Revert if the supplied amount is equal to zero.
        if (amount == 0) {
            revert ZeroAmount(instructionId);
        }
    }

    /**
     * @dev Internal view function to ensure that {sender} and {recipient} in a given
     *      instruction are non-zero addresses.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertReceiverIsNotZeroAddress(Instruction memory instruction)
        private
        pure
    {
        if (instruction.receiver == address(0)) {
            revert ReceiverIsZeroAddress(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {asset} is a valid contract or null address
     *      for ETH transfers.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertValidAsset(Instruction memory instruction) private view {
        if (
            instruction.asset.code.length <= 0 &&
            instruction.asset != address(0)
        ) {
            revert InvalidAsset(instruction.id);
        }
    }
}