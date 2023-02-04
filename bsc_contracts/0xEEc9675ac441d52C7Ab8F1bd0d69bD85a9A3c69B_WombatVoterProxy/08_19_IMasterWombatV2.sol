// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterWombatV2 {
    function poolInfo(uint256)
        external
        view
        returns (
            // storage slot 1
            address lpToken, // Address of LP token contract.
            uint96 allocPoint, // How many allocation points assigned to this pool. WOMs to distribute per second.
            // storage slot 2
            address rewarder,
            // storage slot 3
            uint256 sumOfFactors, // the sum of all boosted factors by all of the users in the pool
            // storage slot 4
            uint104 accWomPerShare, // 19.12 fixed point. Accumulated WOMs per share, times 1e12.
            uint104 accWomPerFactorShare, // 19.12 fixed point.accumulated wom per factor share
            uint40 lastRewardTimestamp // Last timestamp that WOMs distribution occurs.
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

    function wom() external view returns (address);

    function veWom() external view returns (address);

    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingRewards,
            address[] memory bonusTokenAddress,
            string[] memory bonusTokenSymbol,
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
}