// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2020 adrianleb

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./ERC721Ref.sol";

/**
 * @title BlockArt
 * BlockArt - a contract for my non-fungible BlockArts.
 */
contract BlockArt is ERC721Ref {
    constructor(string memory contractURI) ERC721("BlockArt", "EBA") {
        _setContractURI(contractURI);
    }

    function setContractURI(string memory uri) external onlyOwner {
        _setContractURI(uri);
    }

    /// @dev owner of contract can change token URIs, allowing for later hydrating the metadata for an already owned token
    function setTokenURI(uint256 id, string memory uri) external onlyOwner {
        _setTokenURI(id, uri);
    }

    function burnToken(uint256 id) external onlyOwner {
        _burn(id);
    }
}