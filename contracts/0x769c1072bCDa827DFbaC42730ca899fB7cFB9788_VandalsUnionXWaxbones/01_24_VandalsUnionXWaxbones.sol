// SPDX-License-Identifier: MIT

//  ===================================================================
//    _   _                 _       _       _   _       _
//   | | | |               | |     | |     | | | |     (_)
//   | | | | __ _ _ __   __| | __ _| |___  | | | |_ __  _  ___  _ __
//   | | | |/ _` | '_ \ / _` |/ _` | / __| | | | | '_ \| |/ _ \| '_ \
//   \ \_/ / (_| | | | | (_| | (_| | \__ \ | |_| | | | | | (_) | | | |
//    \___/ \__,_|_| |_|\__,_|\__,_|_|___/  \___/|_| |_|_|\___/|_| |_|
//
//  ===================================================================

pragma solidity ^0.8.14;

import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";
import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";

contract VandalsUnionXWaxbones is MinteebleERC721A, DefaultOperatorFilterer {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, 130, _mintPrice) {}

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function airdrop(address[] memory _addresses, uint256[] memory _amounts)
        public
        onlyOwner
    {
        require(
            totalSupply() + _addresses.length <= maxSupply,
            "Max supply exceeded!"
        );

        require(_addresses.length == _amounts.length, "Array length error");

        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _amounts[i]);
        }
    }
}