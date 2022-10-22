// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../access/ownable/OwnableInternal.sol";

import "./WithdrawableInternal.sol";
import "./IWithdrawableAdmin.sol";

/**
 * @title Withdrawable - Admin - Ownable
 * @notice Allow contract owner to manage who can withdraw funds and how.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:peer-dependencies IWithdrawable
 * @custom:provides-interfaces IWithdrawableAdmin
 */
contract WithdrawableOwnable is IWithdrawableAdmin, OwnableInternal, WithdrawableInternal {
    function setWithdrawRecipient(address recipient) external onlyOwner {
        _setWithdrawRecipient(recipient);
    }

    function lockWithdrawRecipient() external onlyOwner {
        _lockWithdrawRecipient();
    }

    function revokeWithdrawPower() external onlyOwner {
        _revokeWithdrawPower();
    }

    function setWithdrawMode(Mode mode) external onlyOwner {
        _setWithdrawMode(mode);
    }

    function lockWithdrawMode() external onlyOwner {
        _lockWithdrawMode();
    }
}