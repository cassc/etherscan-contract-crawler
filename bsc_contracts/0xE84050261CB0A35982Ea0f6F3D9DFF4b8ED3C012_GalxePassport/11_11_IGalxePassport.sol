/*
    Copyright 2021 Project Galaxy.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

/**
 * @title IGalxePassport
 * @author Galaxy Protocol
 *
 * Interface for operating with GalxePassports.
 */
interface IGalxePassport {
    /* ============ Events =============== */

    /* ============ Functions ============ */

    function isOwnerOf(address, uint256) external view returns (bool);

    function getNumMinted() external view returns (uint256);

    // mint
    function mint(address account, uint256 powah) external returns (uint256);

    function burn(uint256 tokenId) external;

    function revoke(uint256 tokenId) external;
}