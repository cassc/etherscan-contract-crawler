// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IChiefFarmer {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingWaya(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function emergencyWithdraw(uint256 _pid) external;

    function lpToken(uint256 _pid) external view returns (address);

    function poolLength() external view returns (uint256 pools);

    function getBoostMultiplier(address _user, uint256 _pid) external view returns (uint256);

    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external;
}