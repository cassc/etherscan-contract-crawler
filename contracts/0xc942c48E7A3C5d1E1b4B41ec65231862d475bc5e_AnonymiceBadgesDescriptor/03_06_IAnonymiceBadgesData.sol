// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IAnonymiceBadgesData {
    struct Badge {
        string image;
        string nameLine1;
        string nameLine2;
    }

    function getBadgePlaceholder() external view returns (string memory);

    function getFontSource() external view returns (string memory);

    function getBoardImage(uint256 badgeId) external view returns (string memory);

    function getBadge(uint256 badgeId) external view returns (Badge memory);

    function getBadgeRaw(uint256 badgeId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        );
}