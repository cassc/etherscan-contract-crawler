// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    /**
     * @notice deposit into convex, receive a tokenized deposit.
     * Parameter to stake immediately.
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    /// @notice burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function poolInfo(uint256 index) external view returns (PoolInfo memory);
}