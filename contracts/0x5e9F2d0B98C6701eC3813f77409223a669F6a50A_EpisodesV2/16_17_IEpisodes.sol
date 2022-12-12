// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEpisodes {
    function burnEpisodes(address ownerId, uint256[] calldata episodeIds)
        external;
}