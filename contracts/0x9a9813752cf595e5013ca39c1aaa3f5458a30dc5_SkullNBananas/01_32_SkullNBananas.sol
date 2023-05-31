// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/customs/MinteebleDynamicCollection_SimpleMultiWhitelist.sol";
import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";

contract SkullNBananas is
    MinteebleDynamicCollection_SimpleMultiWhitelist,
    DefaultOperatorFilterer
{
    constructor()
        MinteebleDynamicCollection_SimpleMultiWhitelist(
            "Skull N Bananas",
            "SNB",
            7777,
            110000000000000000
        )
    {
        revealed = false;
        paused = true;
        setPreRevealUri(
            "ipfs://bafkreibi5v4mk57iqco7zbwtpx23yc4gk3gek23tr22uij7tbtsezwiqdu"
        );
        _safeMint(owner(), 1);

        createWhitelistGroup(
            0,
            0x36e31cc56c14028aaa2143db787d872c2220798f0ee44e017b641ed5d06d146d,
            0
        );

        createWhitelistGroup(
            1,
            0xa2e28039930f6b6cbae13b612c2a7a57be91a2e289a26a0311fdc9a2d0357405,
            53000000000000000
        );

        createWhitelistGroup(
            2,
            0x2a5e3b37617397027154f998383f61574f2b66092df7b2e793aa48c482d305ba,
            53000000000000000
        );

        createWhitelistGroup(
            3,
            0x343750465941b29921f50a28e0e43050e5e1c2611a3ea8d7fe1001090d5e1436,
            110000000000000000
        );
    }

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
}