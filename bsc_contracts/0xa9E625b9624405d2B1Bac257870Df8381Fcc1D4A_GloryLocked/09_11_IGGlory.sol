// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

/**
 * @dev Interface of the gGlory
 */
interface IGGlory {
    struct Breeding {
        uint48 unlockTime;
        uint104 gloryAmount;
        uint104 gGloryAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        uint256[10] reserved;
        Breeding[] breedings;
    }

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserOverview(
        address _addr
    ) external view returns (uint256 gloryLocked, uint256 gGloryBalance);

    function getUserInfo(
        address addr
    ) external view returns (Breeding[] memory);

    function mint(
        uint256 amount,
        uint256 lockDays
    ) external returns (uint256 gGloryAmount);

    function burn(uint256 slot) external;

    function update(
        uint256 slot,
        uint256 lockDays
    ) external returns (uint256 newGGloryAmount);
}