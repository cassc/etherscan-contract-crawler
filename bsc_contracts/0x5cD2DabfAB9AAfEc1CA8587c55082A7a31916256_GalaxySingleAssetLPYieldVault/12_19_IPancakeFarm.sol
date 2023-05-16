// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICakePool {
    function deposit(uint256 _amount, uint256 _lockDuration) external;
    function withdraw(uint256 _shares) external;
}

interface IFarmBoosterProxyFactory {
    function masterchefV2() external view returns (address);
    function Farm_Booster() external view returns (address);
    function createFarmBoosterProxy() external;
    function proxyContract(address proxy) external returns (address);
}

interface IFarmBoosterProxy {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
}

interface IFarmBooster {
    function activate(uint256 _pid) external;
    function deactivate(uint256 _pid) external;
}