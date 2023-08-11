// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IDForceStake {
    function stake(uint256 _value) external;

    function withdraw(uint256 _value) external;

    function exit() external;

    function getReward() external;

    function earned(address _holder) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function df() external view returns (address);

    function lockedDetails() external view returns (bool, uint256);
}