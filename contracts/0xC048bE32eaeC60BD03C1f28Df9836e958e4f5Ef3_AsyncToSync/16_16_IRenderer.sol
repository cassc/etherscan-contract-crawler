// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAsyncToSync} from "./IAsyncToSync.sol";

interface IRenderer {
    function tokenURI(uint256 tokenId, IAsyncToSync.MusicParam memory musicParam) external view returns (string memory);
}