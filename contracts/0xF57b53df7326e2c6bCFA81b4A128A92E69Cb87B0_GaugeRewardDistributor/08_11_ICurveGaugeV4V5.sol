// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

interface ICurveGaugeV4V5 {
  function reward_data(address _token)
    external
    view
    returns (
      address token,
      address distributor,
      uint256 period_finish,
      uint256 rate,
      uint256 last_update,
      uint256 integral
    );

  function deposit(uint256 _value) external;

  function deposit(uint256 _value, address _addr) external;

  function deposit(
    uint256 _value,
    address _addr,
    bool _claim_rewards
  ) external;

  function withdraw(uint256 _value) external;

  function withdraw(uint256 _value, bool _claim_rewards) external;

  function user_checkpoint(address addr) external returns (bool);

  function claim_rewards(address _reward_token) external;

  function claim_rewards(address _reward_token, address _receiver) external;

  function claimable_reward(address _user, address _reward_token) external view returns (uint256);

  function claimable_tokens(address _user) external view returns (uint256);

  function add_reward(address _reward_token, address _distributor) external;

  function set_reward_distributor(address _reward_token, address _distributor) external;

  function deposit_reward_token(address _reward_token, uint256 _amount) external;
}