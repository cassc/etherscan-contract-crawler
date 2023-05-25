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

import 'erc721a/contracts/ERC721A.sol';

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

contract OriginERC721a_v1 is ERC721A, PaymentSplitter, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    string public baseURI;
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _base,
        uint256 _maxSupply,
        address _minter,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A(_name, _symbol) PaymentSplitter(_payees, _shares) {
        require(_maxSupply > 0);
        baseURI = _base;
        maxSupply = _maxSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        if (_minter != address(0)) {
            _setupRole(MINTER_ROLE, _minter);
        } else {
            _setupRole(MINTER_ROLE, _msgSender());
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Return URI to contract metadata JSON file
     * @return URI to JSON file
     */
    function contractURI() public view returns (string memory) {
        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, 'contract.json'))
                : '';
    }

    function setBaseURI(string calldata _base)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _base;
    }

    /**
     * @notice Owner provided signature allows anyone to mint an NFT
     * @param to address that will own the NFT
     * @param count number of NFTs to mint
     * @param price total ETH that must be sent to the contract to mint NFTs
     * @param mintLimit max number of NFTs that can be minted to this owner
     * @param expires block timestamp after which this call is no longer valid
     */
    function mint(
        address to,
        uint256 count,
        uint256 price,
        uint256 mintLimit,
        uint256 expires,
        bytes memory sig
    ) external payable {
        require(_numberMinted(to) + count <= mintLimit, 'Max mint limit');
        require(totalSupply() + count <= maxSupply, 'Max supply exceeded');
        require(block.timestamp <= expires, 'Signature expired');
        require(msg.value >= price, 'Not enough ETH');

        bytes32 msgHash = keccak256(
            abi.encode(
                block.chainid,
                address(this),
                _msgSender(),
                to,
                count,
                price,
                mintLimit,
                expires
            )
        );

        address addr = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(msgHash),
            sig
        );
        require(hasRole(MINTER_ROLE, addr), 'Invalid signer');

        _safeMint(to, count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}