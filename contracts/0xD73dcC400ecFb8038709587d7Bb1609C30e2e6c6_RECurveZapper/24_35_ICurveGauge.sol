// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./ICurveStableSwap.sol";

interface ICurveGauge is IERC20Full
{
    struct Reward
    {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function lp_token() external view returns (ICurveStableSwap);
    function deposit(uint256 amount, address receiver, bool _claim_rewards) external;
    function withdraw(uint256 amount, bool _claim_rewards) external;
    function claim_rewards(address addr) external;
    function working_supply() external view returns (uint256);
    function working_balances(address _user) external view returns (uint256);
    function claimable_tokens(address _user) external view returns (uint256);
    function claimable_reward(address _user, address _token) external view returns (uint256);
    function claimed_reward(address _user, address _token) external view returns (uint256);
    function reward_tokens(uint256 index) external view returns (address);
    function deposit_reward_token(address _token, uint256 amount) external;
    function reward_count() external view returns (uint256);
    function reward_data(address token) external view returns (Reward memory);
    
    /** Permission works only on sidechains */
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
}