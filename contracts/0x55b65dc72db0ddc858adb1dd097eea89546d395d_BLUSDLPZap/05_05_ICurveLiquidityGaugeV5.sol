// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ICurveLiquidityGaugeV5 is IERC20 {
    // Public state getters

    function reward_data(address _reward_token) external returns (
        address token,
        address distributor,
        uint256 period_finish,
        uint256 rate,
        uint256 last_update,
        uint256 integral
    );

    // User-facing functions

    function deposit(uint256 _value) external;
    function deposit(uint256 _value, address _addr) external;
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 _value) external;
    function withdraw(uint256 _value, bool _claim_rewards) external;

    function claim_rewards() external;
    function claim_rewards(address _addr) external;
    function claim_rewards(address _addr, address _receiver) external;

    function user_checkpoint(address addr) external returns (bool);
    function set_rewards_receiver(address _receiver) external;
    function kick(address addr) external;

    // Admin functions

    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
    function set_killed(bool _is_killed) external;

    // View methods

    function claimed_reward(address _addr, address _token) external view returns (uint256);
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claimable_tokens(address addr) external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);
    function future_epoch_time() external view returns (uint256);
    function inflation_rate() external view returns (uint256);

    function version() external view returns (string memory);
}