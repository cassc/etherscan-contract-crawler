// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILockingLogo.sol";

interface ILockingPositionManager {
    function ownerOf(uint256 tokenId) external view returns (address);

    function owner() external view returns (address);

    function mint(address account) external;

    function burn(uint256 tokenId) external;

    function nextId() external view returns (uint256);

    function getComplianceInfo(uint256 tokenId) external view returns (address, uint256);

    function logoInfo(uint256 tokenId) external view returns (ILockingLogo.LogoInfos memory);

    function unlockingTimestampPerToken(uint256 tokenId) external view returns (uint256);
}