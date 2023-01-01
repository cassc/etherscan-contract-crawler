// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../access/ownable/OwnableInternal.sol";

import "./WithdrawableStorage.sol";
import "./IWithdrawableInternal.sol";

/**
 * @title Functionality to withdraw ERC20 or natives tokens from the contract via various modes
 */
abstract contract WithdrawableInternal is IWithdrawableInternal, OwnableInternal {
    using Address for address payable;
    using WithdrawableStorage for WithdrawableStorage.Layout;

    function _withdrawRecipient() internal view virtual returns (address) {
        return WithdrawableStorage.layout().recipient;
    }

    function _withdrawRecipientLocked() internal view virtual returns (bool) {
        return WithdrawableStorage.layout().recipientLocked;
    }

    function _withdrawPowerRevoked() internal view virtual returns (bool) {
        return WithdrawableStorage.layout().powerRevoked;
    }

    function _withdrawMode() internal view virtual returns (Mode) {
        return WithdrawableStorage.layout().mode;
    }

    function _withdrawModeLocked() internal view virtual returns (bool) {
        return WithdrawableStorage.layout().modeLocked;
    }

    function _setWithdrawRecipient(address recipient) internal virtual {
        WithdrawableStorage.Layout storage l = WithdrawableStorage.layout();

        if (l.recipientLocked) {
            revert ErrWithdrawRecipientLocked();
        }

        l.recipient = recipient;

        emit WithdrawRecipientChanged(recipient);
    }

    function _lockWithdrawRecipient() internal virtual {
        WithdrawableStorage.layout().recipientLocked = true;

        emit WithdrawRecipientLocked();
    }

    function _revokeWithdrawPower() internal virtual {
        WithdrawableStorage.layout().powerRevoked = true;

        emit WithdrawPowerRevoked();
    }

    function _setWithdrawMode(Mode _mode) internal virtual {
        WithdrawableStorage.Layout storage l = WithdrawableStorage.layout();

        if (l.modeLocked) {
            revert ErrWithdrawModeLocked();
        }

        l.mode = _mode;

        emit WithdrawModeChanged(_mode);
    }

    function _lockWithdrawMode() internal virtual {
        WithdrawableStorage.layout().modeLocked = true;

        emit WithdrawModeLocked();
    }

    function _withdraw(address[] calldata claimTokens, uint256[] calldata amounts) internal virtual {
        WithdrawableStorage.Layout storage l = WithdrawableStorage.layout();

        /**
         * We are using msg.sender for smaller attack surface when evaluating
         * the sender of the function call. If in future we want to handle "withdraw"
         * functionality via meta transactions, we should consider using `_msgSender`
         */

        if (l.mode == Mode.NOBODY) {
            revert ErrWithdrawImpossible();
        } else if (l.mode == Mode.RECIPIENT) {
            if (l.recipient != msg.sender) {
                revert ErrWithdrawOnlyRecipient();
            }
        } else if (l.mode == Mode.OWNER) {
            if (_owner() != msg.sender) {
                revert ErrWithdrawOnlyOwner();
            }
        }

        if (l.powerRevoked) {
            revert ErrWithdrawImpossible();
        }

        if (l.recipient == address(0)) {
            revert ErrWithdrawRecipientNotSet();
        }

        for (uint256 i = 0; i < claimTokens.length; i++) {
            if (claimTokens[i] == address(0)) {
                payable(l.recipient).sendValue(amounts[i]);
            } else {
                IERC20(claimTokens[i]).transfer(address(l.recipient), amounts[i]);
            }
        }

        emit Withdrawn(claimTokens, amounts);
    }
}