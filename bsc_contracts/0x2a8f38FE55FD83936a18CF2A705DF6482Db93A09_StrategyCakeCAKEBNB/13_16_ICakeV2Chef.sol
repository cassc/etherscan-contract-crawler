// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ICakeV2Chef {
    // function deposit(uint256 _pid, uint256 _amount) external;
    // function withdraw(uint256 _pid, uint256 _amount) external;
    // function enterStaking(uint256 _amount) external;
    // function leaveStaking(uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    // function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    // function emergencyWithdraw(uint256 _pid) external;
     function deposit(uint256 _pid, uint256 _amount) external;
        function withdraw(uint256 _pid, uint256 _amount) external;
        function emergencyWithdraw(uint256 _pid) external;
        function lpToken(uint256 _pid) external view returns (address);
        function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
}