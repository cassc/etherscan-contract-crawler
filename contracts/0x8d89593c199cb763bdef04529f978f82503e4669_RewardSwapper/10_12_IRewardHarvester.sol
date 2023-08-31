// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRewardHarvester {
    /**
        @notice Return the default token address
     */
    function defaultToken() external view returns (address);

    /**
        @notice Deposit `defaultToken` to this contract
        @param  _amount  uint256  Amount of `defaultToken` to deposit
     */
    function depositReward(uint256 _amount) external;
}