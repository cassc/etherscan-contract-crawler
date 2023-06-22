// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IForgottenRunesComic is IERC1155 {
    function mint(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mintToMultipleRecipients(
        address[] calldata recipients,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}