// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPort3Airdrop {
    function disperseEther(address[] memory recipients, uint256[] memory values) external payable;
    function disperseToken(address token, address[] memory recipients, uint256[] memory values) external;
    function feeOf(uint256 amount) external view returns (uint256);

}