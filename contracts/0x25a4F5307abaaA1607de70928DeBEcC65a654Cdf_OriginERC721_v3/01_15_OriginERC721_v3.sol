/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2021 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract OriginERC721_v3 is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _base;

    function initialize(
        address owner,
        address minter,
        string memory name,
        string memory symbol,
        string memory baseURI
    ) initializer public  {
        __AccessControl_init();
        __ERC721_init(name, symbol);
        _base = baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);

        if (minter != address(0)) {
            _setupRole(MINTER_ROLE, minter);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _base;
    }

    /**
     * @notice Return URI to contract metadata JSON file
     * @return URI to JSON file
     */
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "";
    }

    /**
     * @notice Change the base url for all NFTs
     */
    function setBaseURI(string calldata base) external onlyRole(MINTER_ROLE) {
        _base = base;
    }

    /**
     * @notice Mint multiple NFTs
     * @param to address that new NFTs will belong to
     * @param tokenIds ids of new NFTs to create
     * @param preApprove optional account that is pre-approved to move tokens
     *                   after token creation.
     */
    function massMint(
        address to,
        uint256[] calldata tokenIds,
        address preApprove
    ) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
            if (preApprove != address(0)) {
                _approve(preApprove, tokenIds[i]);
            }
        }
    }

    /**
     * @notice Mint a single nft
     */
    function safeMint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Mint a single nft to a creator, then transfer to a user
     * @param creator address that will show as the creator of the NFT
     * @param to address that new NFTs will belong to
     * @param tokenId id of new NFT
     */
    function mintAndTransfer(
        address creator,
        address to,
        uint256 tokenId
    ) external onlyRole(MINTER_ROLE) {
        _mint(creator, tokenId);
        _safeTransfer(creator, to, tokenId, "");
    }
}