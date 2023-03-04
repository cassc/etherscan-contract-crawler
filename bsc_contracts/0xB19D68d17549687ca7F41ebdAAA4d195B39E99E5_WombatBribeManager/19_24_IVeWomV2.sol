// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the VeWom
 */
interface IVeWom {
    struct Breeding {
        uint48 unlockTime;
        uint104 womAmount;
        uint104 veWomAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        uint256[10] reserved;
        Breeding[] breedings;
    }

    function usedVote(address _user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserInfo(address addr) external view returns (UserInfo memory);

    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);

    function burn(uint256 slot) external;

    function update(uint256 slot, uint256 lockDays) external returns (uint256 newVeWomAmount);
}