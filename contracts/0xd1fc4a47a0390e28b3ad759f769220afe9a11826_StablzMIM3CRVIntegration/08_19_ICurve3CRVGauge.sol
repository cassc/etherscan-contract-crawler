//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVGauge {

    function deposit(uint _value) external;

    function withdraw(uint _value) external;

    function claim_rewards() external;

    function balanceOf(address _address) external view returns (uint);

    function claimed_reward(address _address, address _reward_token) external view returns (uint);

    function claimable_reward(address _address, address _reward_token) external view returns (uint);

    function claimable_tokens(address _address) external returns (uint);

    function deposit_reward_token(address _reward_token, uint _amount) external;

}