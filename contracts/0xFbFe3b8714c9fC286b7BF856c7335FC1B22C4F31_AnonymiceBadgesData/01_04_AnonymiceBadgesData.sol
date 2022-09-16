// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnonymiceBadgesData.sol";

contract AnonymiceBadgesData is Ownable {
    mapping(uint256 => IAnonymiceBadgesData.Badge) public badges;
    mapping(uint256 => string) public boardImages;
    string public badgePlaceholder;
    string public fontSource;

    function getBoardImage(uint256 boardId) external view returns (string memory) {
        return boardImages[boardId];
    }

    function getBadge(uint256 badgeId) external view returns (IAnonymiceBadgesData.Badge memory) {
        return badges[badgeId];
    }

    function getBadgeRaw(uint256 badgeId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        IAnonymiceBadgesData.Badge memory badge = badges[badgeId];
        return (badge.image, badge.nameLine1, badge.nameLine2);
    }

    function getBadgePlaceholder() external view returns (string memory) {
        return badgePlaceholder;
    }

    function getFontSource() external view returns (string memory) {
        return fontSource;
    }

    function setBadgePlaceholder(string memory image) external onlyOwner {
        badgePlaceholder = image;
    }

    function setBoardImage(uint256 boardId, string memory image) external onlyOwner {
        boardImages[boardId] = image;
    }

    function setFontSource(string memory _fontSoruce) external onlyOwner {
        fontSource = _fontSoruce;
    }

    function setBadgeImage(
        uint256 badgeId,
        string memory image,
        string memory nameLine1,
        string memory nameLine2
    ) external onlyOwner {
        badges[badgeId] = IAnonymiceBadgesData.Badge({image: image, nameLine1: nameLine1, nameLine2: nameLine2});
    }
}