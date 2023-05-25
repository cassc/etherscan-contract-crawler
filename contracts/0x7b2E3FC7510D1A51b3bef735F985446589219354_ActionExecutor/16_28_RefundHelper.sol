// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import './TransferHelper.sol' as TransferHelper;

/**
 * @notice Refunds the extra balance of the native token
 * @dev Reverts on subtraction if the actual balance is less than expected
 * @param _self The address of the executing contract
 * @param _expectedBalance The expected native token balance value
 * @param _to The refund receiver's address
 */
function refundExtraBalance(address _self, uint256 _expectedBalance, address payable _to) {
    uint256 extraBalance = _self.balance - _expectedBalance;

    if (extraBalance > 0) {
        TransferHelper.safeTransferNative(_to, extraBalance);
    }
}