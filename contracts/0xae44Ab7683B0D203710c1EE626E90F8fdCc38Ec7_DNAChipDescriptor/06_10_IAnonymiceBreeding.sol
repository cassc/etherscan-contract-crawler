// SPDX-License-Identifier: MIT

/*
Copyright 2021 Anonymice

Licensed under the Anonymice License, Version 1.0 (the “License”); you may not use this code except in compliance with the License.
You may obtain a copy of the License at https://doz7mjeufimufl7fa576j6kq5aijrwezk7tvdgvzrfr3d6njqwea.arweave.net/G7P2JJQqGUKv5Qd_5PlQ6BCY2JlX51GauYljsfmphYg

Unless required by applicable law or agreed to in writing, code distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAnonymiceBreeding is IERC721Enumerable {
    struct Incubator {
        uint256 parentId1;
        uint256 parentId2;
        uint256 childId;
        uint256 revealBlock;
    }

    function _tokenIdToLegendary(uint256 _tokenId) external view returns (bool);

    function _tokenIdToLegendaryNumber(uint256 _tokenId)
        external
        view
        returns (uint8);

    function _tokenToRevealed(uint256 _tokenId) external view returns (bool);

    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);

    function _tokenToIncubator(uint256 _tokenId)
        external
        view
        returns (Incubator memory);
}