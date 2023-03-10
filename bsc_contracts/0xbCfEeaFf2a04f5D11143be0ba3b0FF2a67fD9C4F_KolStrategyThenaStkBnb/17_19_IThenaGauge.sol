// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IThenaGauge {
    function balanceOf(address account) external view returns (uint);
    function claimFees() external returns (uint claimed0, uint claimed1);
    function deposit(uint amount) external;
    function depositAll(uint amount) external;
    function earned(address account) external view returns (uint);
    function getReward() external;
    function withdraw(uint amount) external;
    function withdrawAll() external;
    function withdrawAllAndHarvest(uint amount) external;
}