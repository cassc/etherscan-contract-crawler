// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <=0.8.19;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ForjSoulboundERC1155 is ERC1155, Ownable {

    error TokenIsSoulbound();

    string name;
    string symbol;
    string baseURI;

    constructor() ERC1155(""){}

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