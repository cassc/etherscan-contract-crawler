// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICovidGambit {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function owner() external returns (address);
    function startPlandemic(bool isStarted) external;
    function plandemicStarted() external returns(bool);
    function getVaxxed(address patient) external;
    function setMaxWallet(uint256 _maxWallet) external;
    function totalSupply() external view returns (uint256);
    function sneeze(address target) external;
    function transferOwnership(address to) external;
    function patientStatus(address patient) external view returns (uint256);
    function balanceOf(address patient) external view returns (uint256);
    function isVaxxed(address _address) external view returns (bool);
    function firstInfectedTime(address _address) external view returns (uint256);
    function immunityEndTime(address _address) external view returns (uint256);
    function quarantineEndTime(address _address) external view returns (uint256);
    function washHands() external;
    function enterQuarantine() external;
    function plandemicStats(address[] memory patients) external view returns (uint256, uint256, uint256, uint256, uint256);
    function getUnvaxxed(address patient) external;
}