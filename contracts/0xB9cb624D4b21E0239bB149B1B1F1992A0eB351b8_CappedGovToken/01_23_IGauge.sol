// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IERC20.sol";


interface IGauge is IERC20 {

    function deposit(uint256 _value) external;

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_rewards(address _addr, address _receiver) external;

}