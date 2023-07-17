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

import "./ERC721Style.sol";

// import "hardhat/console.sol";

contract BlockStyle is ERC721Style {
    constructor(string memory baseURI, string memory contractURI)
        ERC721("BlockStyle", "EBS")
    {
        _setBaseURI(baseURI);
        _setContractURI(contractURI);
    }

    function setContractURI(string memory uri) external onlyOwner {
        _setContractURI(uri);
    }

    /// @dev BlockStyle token metadata URIs are meant to use base + id concatenation
    function setBase(string memory uri) external onlyOwner {
        _setBaseURI(uri);
    }

    /// @dev BlockStyle tokens have a canvas URI which can be changed by owner
    function setCanvas(uint256 id, string memory canvas) external {
        require(
            _isApprovedOrOwner(_msgSender(), id),
            "Operator is not approved"
        );
        _setCanvasURI(id, canvas);
    }

    /// @dev Opt in specifying token metadata URI
    function setToken(uint256 id, string memory uri) external {
        require(
            _isApprovedOrOwner(_msgSender(), id),
            "Operator is not approved"
        );
        _setTokenURI(id, uri);
    }

    /// @notice BlockArt minting with BlockStyle, supply and fee management
    function setStyleSupplyCap(uint256 _id, uint256 _cap) external {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "Operator is not approved"
        );
        _setStyleSupplyCap(_id, _cap);
    }

    function setStyleFeeMul(uint256 _id, uint256 _value) external {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "Operator is not approved"
        );

        require(_value >= 100, "Value too low");

        _setStyleFeeMul(_id, _value);
    }

    function setStyleFeeMin(uint256 _id, uint256 _value) external {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "Operator is not approved"
        );
        _setStyleFeeMin(_id, _value);
    }
}