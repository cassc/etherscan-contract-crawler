// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";
import "@minteeble/smart-contracts/contracts/token/ERC1155/customs/MinteebleERC1155_Whitelisted.sol";

contract RotationFirstTurn is
    MinteebleERC1155_Whitelisted,
    DefaultOperatorFilterer
{
    constructor()
        MinteebleERC1155_Whitelisted("RotationFirstTurn", "R360", "")
    {
        addId(1);
        setMintPrice(1, 0);
        setMaxSupply(1, 360);
        setPaused(false);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
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
}