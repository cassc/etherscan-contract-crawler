// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev Interface made for the Curve's Gauge contract
 */
interface IGauge {

    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function reward_data(address _reward_token) external view returns(Reward memory);

    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
    function add_reward(address _reward_token, address _distributor) external;
    
}