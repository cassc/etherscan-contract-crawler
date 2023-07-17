// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge {
    function lp_token() external view returns (address);

    function integrate_fraction(address addr) external view returns (uint256);

    function claimable_tokens(address addr) external returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;
}

interface ILiquidityGaugeReward is ILiquidityGauge {
    function reward_contract() external view returns (address);

    function rewarded_token() external view returns (address);
}

interface ILiquidityGaugeV2 is IERC20, ILiquidityGauge {
    function claim_rewards(address addr) external;

    function claim_rewards() external;

    function claimable_reward(address, address) external returns (uint256);

    function reward_integral(address) external view returns (uint256);

    function reward_integral_for(address, address) external view returns (uint256);

    function reward_count() external view returns (uint256);

    function reward_tokens(uint256 _i) external view returns (address);
}

interface ILiquidityGaugeV3 is ILiquidityGaugeV2 {
    function claimable_reward(address addr, address token) external view override returns (uint256);

    function claimable_reward_write(address addr, address token) external returns (uint256);
}

/* solhint-enable */