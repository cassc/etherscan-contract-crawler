// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICVXLocker {
    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function balances(address _user)
        external
        view
        returns (
            uint112 locked,
            uint112 boosted,
            uint32 nextUnlockIndex
        );
}