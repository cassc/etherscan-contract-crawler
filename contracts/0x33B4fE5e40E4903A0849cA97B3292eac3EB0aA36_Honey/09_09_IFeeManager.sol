// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IFeeManager {
    function canSyncFee(address sender, address recipient) external view returns (bool);
    function syncFee() external;
}