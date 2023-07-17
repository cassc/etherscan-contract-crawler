// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ILiquidityGaugeStrat {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    // solhint-disable-next-line
    function claim_rewards_for(address _user, address _recipient) external;

    function claim_rewards(address _user) external;

    // // solhint-disable-next-line
    // function claim_rewards_for(address _user) external;

    // solhint-disable-next-line
    function deposit(uint256 _value, address _addr) external;

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    function withdraw(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 _value, address _addr) external;

    // solhint-disable-next-line
    function reward_data(address _tokenReward) external view returns (Reward memory);

    function balanceOf(address) external returns (uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function commit_transfer_ownership(address) external;

    function initialize(
        address _staking_token,
        address _admin,
        address _SDT,
        address _voting_escrow,
        address _veBoost_proxy,
        address _distributor,
        address _vault,
        string memory _symbol
    ) external;

    function add_reward(address, address) external;

    function set_claimer(address) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function transfer(address _to, uint256 _value) external returns (bool);

    function working_balances(address _address) external returns (uint256);

    function set_reward_distributor(address _rewardToken, address _newDistrib) external;
}