// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILiquidityGauge {
    function deposit(uint256 amount, address receiver) external;

    function withdraw(uint value) external;

    function lp_token() external view returns (address);

    function set_approve_deposit(address depositor, bool can_deposit) external;

    function set_rewards_receiver(address receiver) external;
}