// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IS1Proxy {
    function deposit(uint256 _deposit) external;
    function depositETH() external payable;
    function depositETHWithMin(uint256 _min) external payable;
    function withdraw(uint256 _amount) external returns(uint256);
    function withdrawWithMax(uint256 _amount, uint256 _max) external;
    function claimToDepositor(address _depositor) external returns(uint256);
    function claimToDeployer() external returns(uint256);
}