// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBribeDistribution {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external ;
    function setOwner(address _owner) external;
}