// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICakePool {
    /**
     * @dev Get the user's userInfo from CakePool contract.
     */
    function userInfo(address _userAddress)
        external
        view
        returns (
            uint256 shares,
            uint256 lastDepositedTime,
            uint256 cakeAtLastUserAction,
            uint256 lastUserActionTime,
            uint256 lockStartTime,
            uint256 lockEndTime,
            uint256 userBoostedShare,
            bool locked,
            uint256 lockedAmount
        );

}