// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterWombatV3 {
    function poolInfoV3(uint256)
        external
        view
        returns (
            address lpToken, // Address of LP token contract.
            address rewarder,
            uint40 periodFinish,
            uint128 sumOfFactors, // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
            uint128 rewardRate, // 20.18 fixed point.
            uint104 accWomPerShare, // 19.12 fixed point. Accumulated WOM per share, times 1e12.
            uint104 accWomPerFactorShare, // 19.12 fixed point. Accumulated WOM per factor share
            uint40 lastRewardTimestamp
        );

    function userInfo(uint256, address)
        external
        view
        returns (
            // storage slot 1
            uint128 amount, // 20.18 fixed point. How many LP tokens the user has provided.
            uint128 factor, // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
            // storage slot 2
            uint128 rewardDebt, // 20.18 fixed point. Reward debt. See explanation below.
            uint128 pendingWom // 20.18 fixed point. Amount of pending wom
            //
            // We do some fancy math here. Basically, any point in time, the amount of WOMs
            // entitled to a user but is pending to be distributed is:
            //
            //   ((user.amount * pool.accWomPerShare + user.factor * pool.accWomPerFactorShare) / 1e12) -
            //        user.rewardDebt
            //
            // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
            //   1. The pool's `accWomPerShare`, `accWomPerFactorShare` (and `lastRewardTimestamp`) gets updated.
            //   2. User receives the pending reward sent to his/her address.
            //   3. User's `amount` gets updated.
            //   4. User's `rewardDebt` gets updated.
        );

    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingRewards,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        );

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 transfered,
            uint256[] memory rewards,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;
}