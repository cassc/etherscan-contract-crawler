/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.13;

interface IGuardian {
    /**
     * @notice Returns if Withdrawals are paused or not.
     * @return bool indicating if Withdrawals are paused or not.
     */
    function withdrawPaused() external view returns (bool);

    /**
     * @notice Returns if Deposits are paused or not.
     * @return bool indicating if Deposits are paused or not.
     */
    function depositPaused() external view returns (bool);
}