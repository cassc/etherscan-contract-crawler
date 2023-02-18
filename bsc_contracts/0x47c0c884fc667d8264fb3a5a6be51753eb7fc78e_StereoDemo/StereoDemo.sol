/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StereoDemo {
    struct Song {
        string name;
        string singer;
        string url;
    }

    mapping(address => bool) private _used;
    mapping(address => Song) private _songs;

    function useDemo(string memory _name, string memory _singer, string memory _url) public {
        require(demoUsed(msg.sender) != true, "dev: Sorry you have tested before");

        Song memory _song;
        _song.name = _name;
        _song.singer = _singer;
        _song.url = _url;

        _used[msg.sender] = true;
        _songs[msg.sender] = _song;
    }

    function demoUsed(address _user) public view returns (bool) {
        return(_used[_user]);
    }

    function getSong(address _user) public view returns (Song memory) {
        return(_songs[_user]);
    }
}