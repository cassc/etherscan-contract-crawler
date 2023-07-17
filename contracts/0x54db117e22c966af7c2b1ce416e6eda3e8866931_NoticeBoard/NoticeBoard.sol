/**
 *Submitted for verification at Etherscan.io on 2023-01-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NoticeBoard {
    struct Notice {
        string title;
        string content;
        uint createdDate;
    }

    Notice[] public notices;

    constructor() public {
        notices.push(Notice("Welcome to the Notice Board!", "This is the default notice.", block.timestamp));
    }

    function addNotice(string memory _title, string memory _content) public {
        notices.push(Notice(_title, _content, block.timestamp));
    }

    function updateNotice(uint _index, string memory _title, string memory _content) public {
        Notice memory notice = notices[_index];
        notice.title = _title;
        notice.content = _content;
    }

    function deleteNotice(uint _index) public {
        delete notices[_index];
    }

    function getNoticeCount() public view returns (uint) {
        return notices.length;
    }

    function getNotice(uint _index) public view returns (string memory, string memory, uint) {
        Notice memory notice = notices[_index];
        return (notice.title, notice.content, notice.createdDate);
    }

    function getAllNotices() public view returns (Notice[] memory) {
        return notices;
    }
}