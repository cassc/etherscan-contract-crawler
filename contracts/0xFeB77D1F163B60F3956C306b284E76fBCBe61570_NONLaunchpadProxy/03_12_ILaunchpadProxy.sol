// SPDX-License-Identifier: MIT

//   _   _  ____  _   _   _____ _                            _                     _ _____
//  | \ | |/ __ \| \ | | |_   _| |                          | |                   | |  __ \
//  |  \| | |  | |  \| |   | | | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | |__) | __ _____  ___   _
//  | . ` | |  | | . ` |   | | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` |  ___/ '__/ _ \ \/ / | | |
//  | |\  | |__| | |\  |  _| |_| |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | |   | | | (_) >  <| |_| |
//  |_| \_|\____/|_| \_| |_____|______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_|_|   |_|  \___/_/\_\\__, |
//                                                                | |                                     __/ |
//                                                                |_|                                    |___/                                                          |_|

pragma solidity ^0.8.16;

interface ILaunchpadProxy {
    function getProxyId() external pure returns (bytes4);

    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity
    ) external payable returns (uint256);

    function launchpadSetBaseURI(
        address sender,
        bytes4 launchpadId,
        string memory baseURI
    ) external;

    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address[] calldata accounts
    ) external view returns (uint8[] memory wln);
}