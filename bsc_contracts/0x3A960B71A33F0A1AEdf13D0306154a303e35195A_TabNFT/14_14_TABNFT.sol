/*
    Copyright 2022 Project Galaxy.
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

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITabNFT.sol";

contract TabNFT is ERC721, ITabNFT, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _addressToTokenId;

    uint256 private _tabCount;
    string private _curBaseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_)
    ERC721(name_, symbol_) {
        _tabCount = 0;
        _curBaseURI = string(abi.encodePacked(baseURI_));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public override pure {
        require(false, "disabled");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public override pure {
        require(false, "disabled");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public override pure {
        require(false, "disabled");
    }


    /* ============ External Functions ============ */
    function mint()
    external
    override
    returns (uint256)
    {
        require(
            _addressToTokenId[_msgSender()] != 0,
            "TAB already minted to the address"
        );
        _tabCount++;
        uint256 nextTokenId = _tabCount;

        _mint(_msgSender(), nextTokenId);
        _addressToTokenId[_msgSender()] = nextTokenId;
        return nextTokenId;
    }


    /* ============ External Getter Functions ============ */
    function getTokenIdByAddress(address addr)
    external
    view
    override
    returns (uint256)
    {
        return _addressToTokenId[addr];
    }


    function isOwnerOf(address account, uint256 id)
    public
    view
    override
    returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
    }

    function getNumMinted()
    external
    view
    override
    returns (uint256) {
        return _tabCount;
    }


    function _baseURI() internal view override returns (string memory) {
        return _curBaseURI;
    }
}