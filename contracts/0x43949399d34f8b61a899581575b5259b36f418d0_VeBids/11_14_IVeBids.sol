// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/**
 * @dev Interface of the VeBids
 */
interface IVeBids {
    
    struct Breeding {
        uint48 unlockTime;
        uint104 bidsAmount;
        uint104 veBIDSAmount;
    }

    struct UserInfo {
        Breeding[] breedings;
        uint256 userTotalBidsLocked;
    }

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserOverview(address _addr) external view returns (uint256 womLocked, uint256 veWomBalance);

    function getUserInfo(address addr) external view returns (UserInfo memory);

    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);

    function burn(uint256 slot) external;

    function update(uint256 slot, uint256 lockDays) external returns (uint256 newVeWomAmount);
}