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
import "@minteeble/smart-contracts/contracts/token/ERC1155/MinteebleERC1155.sol";

contract VandalsUnionXCyberBandits is
    MinteebleERC1155,
    DefaultOperatorFilterer
{
    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    ) MinteebleERC1155(name, symbol, uri) {
        addId(1);
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