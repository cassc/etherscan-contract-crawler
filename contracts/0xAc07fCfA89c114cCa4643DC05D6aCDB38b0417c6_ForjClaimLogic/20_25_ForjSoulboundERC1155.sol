// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ForjERC1155} from "contracts/utils/ForjERC1155.sol";

contract ForjSoulboundERC1155 is ForjERC1155 {

    constructor() ForjERC1155(){}

    modifier Soulbound(){
        revert TokenIsSoulbound();
        _;
    }

    function setApprovalForAll(
        address operator, 
        bool approved
    ) public override Soulbound() {}

    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public override Soulbound() {}

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override Soulbound() {}
}