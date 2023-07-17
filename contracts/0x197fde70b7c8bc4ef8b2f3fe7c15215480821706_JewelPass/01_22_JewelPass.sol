// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC1155/MinteebleERC1155.sol";
import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";

contract JewelPass is MinteebleERC1155, DefaultOperatorFilterer {
    constructor() MinteebleERC1155("JewelPass", "JP", "") {
        addId(0);
        addId(1);
        addId(2);

        setMintPrice(0, 50000000000000000);
        setMintPrice(1, 100000000000000000);
        setMintPrice(2, 250000000000000000);

        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function withdrawBalance()
        public
        override
        requireAdmin(msg.sender)
        nonReentrant
    {
        uint256 totBalance = address(this).balance;

        (bool hs1, ) = payable(0x4902368B770F4C0aADe19B5f45BbCbc73c190226).call{
            value: (totBalance / 2)
        }("");
        require(hs1);

        (bool hs2, ) = payable(0x1b1BEe7AB06E4938380E13DD9A56A27cDcf7A107).call{
            value: (totBalance / 2)
        }("");
        require(hs2);
    }
}