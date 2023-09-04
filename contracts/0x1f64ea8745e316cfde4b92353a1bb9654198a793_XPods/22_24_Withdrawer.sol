// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Errors
error NoFundsToWithdraw();
error WithdrawFailed(address recipient, uint256 amount);
error WithdrawToNullAddress();

contract Withdrawer {
    using SafeCast for uint256;

    // Events
    event FundsWithdrawn(address recipient, uint256 amount);

    // the total funds that can be withdrawn by the owner
    uint128 internal withdrawableFunds;

    /**
     * @notice Withdraw function for the owner
     * @dev since only pod sales funds can be withdrawn at any time
     * and users' funds need to be protected, this is marked as nonReentrant
     */
    function _withdraw(address payable receiver) internal {
        // allow the owner to withdraw the balance for any minted pods
        // allow the owner to withdraw the balance
        if (receiver == address(0)) {
            revert WithdrawToNullAddress();
        }

        uint128 funds = withdrawableFunds;
        if (funds == 0) {
            revert NoFundsToWithdraw();
        }

        // reset the withdrawable funds
        withdrawableFunds = 0;

        // emit the withdraw event
        emit FundsWithdrawn(receiver, funds);

        // send the funds to the receiver
        (bool success, ) = receiver.call{value: funds}("");
        if (!success) {
            revert WithdrawFailed(receiver, funds);
        }
    }

    /**
    @dev fallback function to receive ether
     */
    receive() external payable {
        // increase the withdrawable funds by the ETH received
        // += is less gas efficient
        withdrawableFunds = withdrawableFunds + SafeCast.toUint128(msg.value);
    }
}