// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IKOLOMusic {

    struct MusicContent {
        uint8 musicType;         //1-track, 2-work
        uint256 workId;
        uint8 trackNo;          // track index
        uint16 trackNum;        //track cnt
        uint256 extendU;
        string extendS;
    }

    function safeMintMusic(address to, uint256 tokenId, MusicContent memory content) external;

    function getMusicContent(uint256 tokenId) external returns(MusicContent memory);

    function burnMusic(uint256 tokenId)  external;
}