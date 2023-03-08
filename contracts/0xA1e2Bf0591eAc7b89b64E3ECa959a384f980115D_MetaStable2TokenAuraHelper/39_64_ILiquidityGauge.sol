// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge is IERC20 {
    function deposit(uint256 value) external;

    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 value, bool claim_rewards) external;

    function claim_rewards() external;

    // curve & balancer use lp_token()
    function lp_token() external view returns (address);

    // angle use staking_token()
    function staking_token() external view returns (address);

    function reward_tokens(uint256 i) external view returns (address token);

    function reward_count() external view returns (uint256 nTokens);

    function user_checkpoint(address addr) external returns (bool);
}