// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IRefundable.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @notice Provides a _refundGas() function that can be used for inhering contracts to refund user gas cost
/// @dev This functionality is inherited by Governance.sol (for proposing and voting) and Staking.sol (for staking and delegating)
contract Refundable is IRefundable, FrankenDAOErrors {

    /// @notice The maximum priority fee used to cap gas refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice Gas used before _startGas or after refund
    /// @dev Includes 21K TX base, 3.7K for other overhead, and 2.3K for ETH transfer 
    /** @dev This will be slightly different depending on which function is used, but all are within a few 
        thousand gas, so approximation is fine. */
    uint256 public constant REFUND_BASE_GAS = 27_000;

    /// @notice Calculate the amount spent on gas and send that to msg.sender from the contract's balance
    /// @param _startGas gasleft() at the start of the transaction, used to calculate gas spent
    /// @dev Forked from NounsDAO: https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOLogicV2.sol#L1033-L1046
    function _refundGas(uint256 _startGas) internal {
        unchecked {
            uint256 gasPrice = _min(tx.gasprice, block.basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = _startGas - gasleft() + REFUND_BASE_GAS;
            uint refundAmount = gasPrice * gasUsed;
            
            // If gas fund runs out, pay out as much as possible and emit warning event.
            if (address(this).balance < refundAmount) {
                emit InsufficientFundsForRefund(msg.sender, refundAmount, address(this).balance);
                refundAmount = address(this).balance;
            }

            // There shouldn't be any reentrancy risk, as this is called last at all times.
            // They also can't exploit the refund by wasting gas before we've already finalized amount.
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');

            // Includes current balance in event so team can listen and filter to know when to propose refill.
            emit IssueRefund(msg.sender, refundAmount, refundSent, address(this).balance);
        }
    }

    /// @notice Returns the lower value of two uints
    /// @param a First uint
    /// @param b Second uint
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}