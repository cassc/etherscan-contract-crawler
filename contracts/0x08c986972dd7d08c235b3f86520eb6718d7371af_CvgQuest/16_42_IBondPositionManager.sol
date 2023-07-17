// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBondStruct.sol";
import "./IBondLogo.sol";

interface IBondPositionManager {
    // Deposit Principle token in Treasury through Bond contract
    function mint(address account) external;

    function burn(uint256 tokenId) external;

    function nextId() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function bondPerTokenId(uint256 tokenId) external view returns (address);

    function unlockingTimestampPerToken(uint256 tokenId) external view returns (uint256);

    function logoInfo(uint256 tokenId) external view returns (IBondLogo.LogoInfos memory);
}