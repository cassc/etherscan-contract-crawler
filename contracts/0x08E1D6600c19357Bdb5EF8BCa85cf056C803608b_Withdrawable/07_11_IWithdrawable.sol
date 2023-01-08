// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./IWithdrawableInternal.sol";

interface IWithdrawable is IWithdrawableInternal {
    function withdraw(address[] calldata claimTokens, uint256[] calldata amounts) external;

    function withdrawRecipient() external view returns (address);

    function withdrawRecipientLocked() external view returns (bool);

    function withdrawPowerRevoked() external view returns (bool);

    function withdrawMode() external view returns (Mode);

    function withdrawModeLocked() external view returns (bool);
}