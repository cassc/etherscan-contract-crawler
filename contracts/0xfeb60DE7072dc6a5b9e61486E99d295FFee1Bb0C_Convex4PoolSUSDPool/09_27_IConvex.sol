// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IConvex {
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    // deposit lp tokens and stake
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // deposit all lp tokens and stake
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    // withdraw lp tokens
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    // withdraw all lp tokens
    function withdrawAll(uint256 _pid) external returns (bool);

    // claim crv + extra rewards
    function earmarkRewards(uint256 _pid) external returns (bool);

    // claim  rewards on stash (msg.sender == stash)
    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    // delegate address votes on dao (needs to be voteDelegate)
    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight) external returns (bool);
}

interface Rewards {
    function pid() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function stakingToken() external view returns (address);

    function stake(uint256) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address, uint256) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function donate(uint256 _amount) external returns (bool);
}