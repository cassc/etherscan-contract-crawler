// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../roles/OperatorRole.sol";

contract TransferProxy is OperatorRole {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        address token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator {
        IERC1155(token).safeTransferFrom(_from, _to, _id, _value, _data);
    }
}