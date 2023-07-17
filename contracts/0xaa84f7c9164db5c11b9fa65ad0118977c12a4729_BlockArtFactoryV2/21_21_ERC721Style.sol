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

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";

abstract contract ERC721Style is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _ids; // for tracking token IDs

    mapping(uint256 => string) private _scu; // style canvas uris
    mapping(uint256 => uint256) private _ssc; // style suply cap
    mapping(uint256 => address) private _stc; // style to creator
    mapping(uint256 => uint256) private _sfmu; // style fee multiplier
    mapping(uint256 => uint256) private _sfmi; // style fee minimum
    string _contractURI;

    /// @dev Mint BlockStyle NFTs, called by contract owner
    /// @param to The token receiver
    /// @param cap Initial supply cap
    /// @param feeMul Initial Fee Multiplier
    /// @param feeMin Initial Minimum Fee
    /// @param canvas The token canvas URI
    function mint(
        address to,
        uint256 cap,
        uint256 feeMul,
        uint256 feeMin,
        string memory canvas
    ) external onlyOwner {
        _ids.increment();
        uint256 newId = _ids.current();

        _safeMint(to, newId);
        _setCreator(newId, to);
        _setStyleSupplyCap(newId, cap);
        _setStyleFeeMul(newId, feeMul);
        _setStyleFeeMin(newId, feeMin);
        _setCanvasURI(newId, canvas);
    }

    /// @notice Setters
    function _setStyleSupplyCap(uint256 id, uint256 cap) internal virtual {
        require(_exists(id), "");
        _ssc[id] = cap;
    }

    function _setCreator(uint256 id, address who) internal virtual {
        require(_exists(id), "");
        _stc[id] = who;
    }

    function _setStyleFeeMul(uint256 id, uint256 amount) internal virtual {
        require(_exists(id), "");
        _sfmu[id] = amount;
    }

    function _setStyleFeeMin(uint256 id, uint256 amount) internal virtual {
        require(_exists(id), "");
        _sfmi[id] = amount;
    }

    /// @notice Getters

    function getStyleSupplyCap(uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        require(_exists(id), "");
        return _ssc[id];
    }

    function getCreator(uint256 id) public view virtual returns (address) {
        require(_exists(id), "");
        return _stc[id];
    }

    function getStyleFeeMul(uint256 id) public view virtual returns (uint256) {
        require(_exists(id), "");
        return _sfmu[id];
    }

    function getStyleFeeMin(uint256 id) public view virtual returns (uint256) {
        require(_exists(id), "");
        return _sfmi[id];
    }

    /// @notice Canvas URI management, by token owner

    function _setCanvasURI(uint256 id, string memory uri) internal virtual {
        require(_exists(id), "ID not found");
        _scu[id] = uri;
    }

    function canvasURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ID Not Found");
        return _scu[tokenId];
    }

    /// @notice Contract metadata URI management, only by owner

    function _setContractURI(string memory uri) internal virtual onlyOwner {
        _contractURI = uri;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
}