// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICurveGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function deposit_reward_token(address _reward_token, uint256 _amount) external;

    function set_reward_distributor(address _reward_token, address _distributor) external;

    function reward_data(
        address _reward_token
    ) external returns (address, address, uint256, uint256, uint256, uint256);
}