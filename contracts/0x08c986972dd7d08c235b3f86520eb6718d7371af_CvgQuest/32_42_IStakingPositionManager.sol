// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingLogo.sol";

interface IStakingPositionManager {
    function mint(address account) external;

    function burn(uint256 tokenId) external;

    function nextId() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getComplianceInfo(uint256 tokenId) external view returns (address, address, uint256);

    function stakingPerTokenId(uint256 tokenId) external view returns (address);

    function unlockingTimestampPerToken(uint256 tokenId) external view returns (uint256);

    function logoInfo(uint256 tokenId) external view returns (IStakingLogo.LogoInfos memory);
}