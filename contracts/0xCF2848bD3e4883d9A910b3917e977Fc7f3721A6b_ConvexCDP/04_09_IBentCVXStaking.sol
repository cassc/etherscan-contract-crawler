// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IBentCVXStaking {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function bentCVX() external view returns (address);
    function addRewarder(address _rewarder) external;
    function removeRewarder(uint256 _index) external;
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claimAll() external;
    function claim(uint256[][] memory _indexes) external;
}