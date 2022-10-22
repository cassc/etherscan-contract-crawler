// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IWithdrawable.sol";

interface IWithdrawableAdmin {
    function setWithdrawRecipient(address _recipient) external;

    function lockWithdrawRecipient() external;

    function revokeWithdrawPower() external;

    function setWithdrawMode(IWithdrawable.Mode _mode) external;

    function lockWithdrawMode() external;
}