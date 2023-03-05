// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDSWISEVault {
    function depositEther() external payable;

    function withdrawEther(uint256 _ethAmount) external;

    function balanceOfsETH2() external returns (uint256);

    function balanceOfrETH2() external returns (uint256);

    function getETHBalance() external returns (uint256);
}