// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISaitaChef {
    function add(uint256 _allocPoint, address _lpToken, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external returns(uint256);
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFees, uint256 _withdrawalFees, bool _withUpdate) external;
    function deposit(address user, uint256 pid, uint256 amount) external payable returns(uint256);
    function withdraw(address user, uint256 pid, uint256 amount) external payable;
    function harvest(address user, uint256 pid) external payable returns(uint256);
    
    function pendingSaita(uint256 _pid, address _user) external view returns (uint256);
    function updateRewardPerBlock(uint256 _newRate) external;
    
    function emergencyWithdraw(address user, uint256 pid) external payable returns(uint256);
    function updateEmergencyFees(uint256 newFee) external ;
    function updatePlatformFee(uint256 newFee) external;
    function updateFeeCollector(address newWallet) external;
    function updateTreasuryWallet(address newTreasurywallet) external;
    function updateRewardWallet(address newWallet) external;

    function updateMultiplier(uint256 _multiplier) external;
    function poolLength() external view returns(uint256);
    function userInfo(uint256 pid, address user) external view returns(uint256, uint256);
    function updatePool(uint256 pid) external;
    function massUpdatePools() external;
}