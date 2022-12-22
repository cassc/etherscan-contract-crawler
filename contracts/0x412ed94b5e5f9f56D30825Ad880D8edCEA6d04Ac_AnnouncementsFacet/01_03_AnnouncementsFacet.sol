// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage, Modifiers, Announcement} from "../libraries/LibAppStorage.sol";

/**
 * @title AnnouncementsFacet
 * @author PartyFinance
 * @notice Facet that lets read, create, update and delete announcements.
 */
contract AnnouncementsFacet is Modifiers {
    /**
     * @notice Create a Party announcement
     * @dev Managers are the only allowed to create announcements
     * @param title Title of the announcement
     * @param content Content of the announcement
     * @param url Content URL added to the announcemnt
     * @param img Image uri of the announcement
     */
    function createAnnouncement(
        string memory title,
        string memory content,
        string memory url,
        string memory img
    ) external onlyManager {
        s.announcements.push(
            Announcement(title, content, url, img, block.timestamp, 0)
        );
    }

    /**
     * @notice Gets the Party announcements
     * @return Array of Announcement structs
     */
    function getAnnouncements() external view returns (Announcement[] memory) {
        return s.announcements;
    }

    /**
     * @notice Gets a single Party announcement
     * @param i Index of the announcement
     * @return Announcement struct
     */
    function getAnnouncement(uint256 i)
        external
        view
        returns (Announcement memory)
    {
        return s.announcements[i];
    }

    /**
     * @notice Edit a Party announcement
     * @dev Managers are the only allowed to edit an announcement
     * @param title Title of the announcement
     * @param content Content of the announcement
     * @param url Content URL added to the announcemnt
     * @param img Image uri of the announcement
     * @param i Index of the announcement
     */
    function editAnnouncement(
        string memory title,
        string memory content,
        string memory url,
        string memory img,
        uint256 i
    ) external onlyManager {
        s.announcements[i].title = title;
        s.announcements[i].content = content;
        s.announcements[i].url = url;
        s.announcements[i].img = img;
        s.announcements[i].updated = block.timestamp;
    }

    /**
     * @notice Remove a Party announcement
     * @dev Managers are the only allowed to remove an announcement
     * @param i Index of the announcement
     */
    function removeAnnouncement(uint256 i) external onlyManager {
        s.announcements[i] = s.announcements[s.announcements.length - 1];
        s.announcements.pop();
    }
}