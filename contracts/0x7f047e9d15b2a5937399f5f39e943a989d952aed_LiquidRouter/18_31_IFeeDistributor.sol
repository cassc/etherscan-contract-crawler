// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeDistributor {
    function claim() external returns (uint256);

    function claim(address _user) external returns (uint256);

    function checkpoint_token() external;

    function checkpoint_total_supply() external;

    function recover_balance(address token) external;

    function kill_me() external;

    function emergency_return() external returns (address);
}