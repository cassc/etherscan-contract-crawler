pragma solidity =0.8.11;

import "IERC20.sol";

interface ILiquidityGauge is IERC20 {
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;
    function withdraw(uint256 _value, bool _claim_rewards) external;
}