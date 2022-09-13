// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IExperienceTracker {
    function levelUp(uint256 id_) external;
    function initialize(uint256 id_) external;

    function isInitialized(uint256 tokenId) external view returns(bool);
    function getLevel(uint256 tokenId) external view returns(uint256);
    function getXp(uint256 tokenId) external view returns(uint256);
    function calculateXpForLevel(uint256 level_) external pure returns(uint256);
}